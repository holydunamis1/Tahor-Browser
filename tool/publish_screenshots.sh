#!/usr/bin/env bash
# Pushes the PNGs in shots/ to the ci-screenshots branch as a single fresh commit,
# using a separate temporary repository so the checkout is never disturbed.
set -euo pipefail
if [ ! -d shots ] || [ -z "$(ls -A shots 2>/dev/null)" ]; then
  echo "No screenshots were taken."
  exit 0
fi
dir="$(mktemp -d)"
cp shots/*.png "$dir/"
printf 'Emulator screenshots of commit %s, run %s.\n' "$GITHUB_SHA" "$GITHUB_RUN_ID" > "$dir/README.txt"
cd "$dir"
git init -q -b ci-screenshots
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A
git commit -q -m "screenshots of ${GITHUB_SHA::7}"
git remote add origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
git push -f origin ci-screenshots
echo "published $(ls "$dir"/*.png | wc -l) screenshots"
