#!/usr/bin/env bash
# Claude Code SessionEnd hook: tear the lab down in the background.
# Hooks get ~1.5s, so detach and return immediately. Log: cluster/down.log
# Opt out (e.g. another session still uses the lab): KUBESTRONAUT_KEEP_CLUSTER=1
set -euo pipefail

[[ "${KUBESTRONAUT_KEEP_CLUSTER:-}" == "1" ]] && exit 0

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# GUI-launched sessions may lack the Homebrew PATH.
export PATH="${PATH}:/opt/homebrew/bin:/usr/local/bin"

# Job control puts the teardown in its own process group, so it survives the session exiting.
set -m
nohup "${ROOT}/cluster/down.sh" >"${ROOT}/cluster/down.log" 2>&1 </dev/null &
disown
exit 0
