#!/usr/bin/env bash
# Size ratchet: fails when a per-ABI release APK (or the IPA) grows more than 3%
# over docs/size-baseline.json. The first release build creates the baseline.
#
# Usage: tool/check_size.sh <apk-directory> [ipa-file]
# Env:   UPDATE_BASELINE=1 rewrites the baseline from the current build.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
python3 - "$@" <<'PY'
import glob, json, os, sys

BASELINE = "docs/size-baseline.json"
THRESHOLD = 3.0
apk_dir = sys.argv[1] if len(sys.argv) > 1 else None
ipa = sys.argv[2] if len(sys.argv) > 2 else None

apks = {}
if apk_dir:
    for p in sorted(glob.glob(os.path.join(apk_dir, "*-release.apk"))):
        apks[os.path.basename(p)] = os.path.getsize(p)
ipa_size = os.path.getsize(ipa) if ipa and os.path.isfile(ipa) else None
if not apks and ipa_size is None:
    print("check_size: no release artifacts found to measure")
    sys.exit(1)

current = {"threshold_percent": THRESHOLD, "apk": apks, "ipa": ipa_size}
if not os.path.isfile(BASELINE) or os.environ.get("UPDATE_BASELINE") == "1":
    existing = {}
    if os.path.isfile(BASELINE):
        existing = json.load(open(BASELINE))
    if ipa_size is None and existing.get("ipa") is not None:
        current["ipa"] = existing["ipa"]
    if not apks and existing.get("apk"):
        current["apk"] = existing["apk"]
    with open(BASELINE, "w") as f:
        json.dump(current, f, indent=2, sort_keys=True)
        f.write("\n")
    print(f"check_size: wrote {BASELINE}")
    for k, v in sorted(apks.items()):
        print(f"  {k}: {v} bytes")
    if ipa_size is not None:
        print(f"  ipa: {ipa_size} bytes")
    sys.exit(0)

base = json.load(open(BASELINE))
limit = base.get("threshold_percent", THRESHOLD)
bad = []
for name, size in apks.items():
    ref = base.get("apk", {}).get(name)
    if ref is None:
        bad.append(f"{name} is not in the baseline; update it deliberately with UPDATE_BASELINE=1")
        continue
    growth = (size - ref) * 100.0 / ref
    print(f"  {name}: {size} bytes vs baseline {ref} ({growth:+.2f}%)")
    if growth > limit:
        bad.append(f"{name} grew {growth:.2f}% (limit {limit}%)")
if ipa_size is not None and base.get("ipa"):
    growth = (ipa_size - base["ipa"]) * 100.0 / base["ipa"]
    print(f"  ipa: {ipa_size} bytes vs baseline {base['ipa']} ({growth:+.2f}%)")
    if growth > limit:
        bad.append(f"ipa grew {growth:.2f}% (limit {limit}%)")
if bad:
    for b in bad:
        print("SIZE-GATE FAIL:", b)
    sys.exit(1)
print("check_size: within the size budget")
PY
