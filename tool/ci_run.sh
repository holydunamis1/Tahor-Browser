#!/usr/bin/env bash
# Runs a command, streams its output, and publishes what matters as GitHub
# annotations so the result can be read through the REST API (raw job logs are
# served from a host that automation sandboxes cannot reach). GitHub keeps only
# 4,096 characters per annotation, so progress bars are dropped, a first
# annotation holds the lines that look like errors, and a second holds the tail.
#
# Usage: tool/ci_run.sh <label> <command...>
# Env:   CI_SHOW=1 also publishes the tail when the command succeeds.
set -uo pipefail
label="${1:?label required}"
shift
log="$(mktemp)"
"$@" 2>&1 | tee "$log"
rc=${PIPESTATUS[0]}
if [ "$rc" -ne 0 ] || [ "${CI_SHOW:-0}" = "1" ]; then
  level="error"
  [ "$rc" -eq 0 ] && level="notice"
  python3 - "$log" "$label" "$rc" "$level" <<'PY'
import re, sys

path, label, rc, level = sys.argv[1:5]
text = open(path, encoding="utf-8", errors="replace").read().replace("\r", "\n")
progress = re.compile(r"^\s*\[[= >]*\]|^\s*(Loading|Fetch remote|Computing updates|Downloading|Installing) ")
lines = [l.rstrip() for l in text.split("\n") if l.strip() and not progress.match(l)]
key = re.compile(r"KGP|Kotlin Gradle Plugin|WARNING:|FAILURE|What went wrong|Execution failed|error:|error •|Error|Exception|e: |not found|Could not|Unresolved|Caused by|BUILD FAILED", re.I)


def esc(s):
    return s.replace("%", "%25").replace("\n", "%0A")


def emit(title, body):
    body = body[-3800:]
    print("::%s title=%s::%s" % (level, title, esc(body)))


hits = []
for i, l in enumerate(lines):
    if key.search(l):
        hits.extend(lines[i:i + 3])
seen, uniq = set(), []
for l in hits:
    if l not in seen:
        seen.add(l)
        uniq.append(l[:240])
if uniq:
    emit("%s ERRORS (exit %s)" % (label, rc), "\n".join(uniq[:40]))
emit("%s TAIL (exit %s)" % (label, rc), "\n".join(l[:240] for l in lines[-40:]))
PY
fi
exit "$rc"
