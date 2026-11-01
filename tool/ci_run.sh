#!/usr/bin/env bash
# Runs a command, streams its output, and publishes the output tail as a GitHub
# annotation so the result can be read through the REST API (raw job logs are
# served from a host that automation sandboxes cannot reach).
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
  msg="$(tail -n 150 "$log" | python3 -c '
import sys
t = sys.stdin.read()[-60000:]
print(t.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A"), end="")
')"
  echo "::${level} title=${label} (exit ${rc})::${msg}"
fi
exit "$rc"
