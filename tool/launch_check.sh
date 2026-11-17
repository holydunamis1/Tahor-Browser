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
adb logcat -d 2>&1 | grep -B2 -A8 -E "GeneratedPluginRegistrant|Error registering plugin" | head -60 > plugins.log
resumed="$(adb shell dumpsys activity activities | grep -m1 -E 'mResumedActivity|topResumedActivity' | tr -d '\r')"

echo "--- resumed activity: ${resumed:-none}"
echo "--- crash buffer:"
cat crash.log
echo "--- plugin registration:"
cat plugins.log
echo "--- error lines:"
cat errors.log

if [ -z "$pid" ] || grep -q "FATAL EXCEPTION" crash.log; then
  echo "LAUNCH-CHECK FAIL: the app is not running or crashed (pid='${pid}')"
  exit 1
fi
echo "LAUNCH-CHECK OK: the app is running (pid ${pid})"
