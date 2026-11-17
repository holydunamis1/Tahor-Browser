#!/usr/bin/env bash
# Installs an APK on the running emulator, launches it, waits, and fails when the
# app crashed or is no longer running. Prints the crash log so a failure can be
# diagnosed from CI output alone.
#
# Usage: tool/launch_check.sh <apk> <package-name>
set -uo pipefail
apk="${1:?apk path required}"
pkg="${2:?package name required}"

adb install -r "$apk" || { echo "LAUNCH-CHECK FAIL: install failed"; exit 1; }
adb logcat -c
adb shell monkey -p "$pkg" -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
sleep 25

pid="$(adb shell pidof "$pkg" | tr -d '\r')"
adb logcat -d -b crash 2>&1 | tail -60 > crash.log
adb logcat -d '*:E' 2>&1 | grep -iE "AndroidRuntime|FATAL|$pkg|MobileAds|APPLICATION_ID|flutter" | tail -40 > errors.log
resumed="$(adb shell dumpsys activity activities | grep -m1 -E 'mResumedActivity|topResumedActivity' | tr -d '\r')"

echo "--- resumed activity: ${resumed:-none}"
echo "--- crash buffer:"
cat crash.log
echo "--- error lines:"
cat errors.log

# Screenshots of the first screens, for inspection. Best effort: a failure here
# never changes the launch verdict.
mkdir -p shots
size="$(adb shell wm size | grep -oE '[0-9]+x[0-9]+' | tail -1)"
W="${size%x*}"
H="${size#*x}"
snap() { adb exec-out screencap -p > "shots/$1.png" 2>/dev/null || true; }
tap() { adb shell input tap "$1" "$2" || true; }
snap 01-start
tap $((W / 2)) $((H * 8 / 100))
sleep 2
snap 02-address-focused
adb shell input text "en.m.wikipedia.org" || true
adb shell input keyevent 66 || true
sleep 12
snap 03-page-loaded
tap $((W * 86 / 100)) $((H * 91 / 100))
sleep 2
snap 04-menu
adb shell input keyevent 4 || true
sleep 1
adb shell cmd uimode night yes || true
sleep 3
snap 05-phone-dark-mode
adb shell cmd uimode night no || true
echo "SCREENSHOTS: $(ls shots | wc -l) taken at ${W}x${H}"

if [ -z "$pid" ] || grep -q "FATAL EXCEPTION" crash.log; then
  echo "LAUNCH-CHECK FAIL: the app is not running or crashed (pid='${pid}')"
  exit 1
fi
echo "LAUNCH-CHECK OK: the app is running (pid ${pid})"
