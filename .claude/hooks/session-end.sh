#!/bin/bash
# SessionEnd (not on /clear or resume; see the matcher in settings.json):
# destroy the lab unless a ./cks terminal still owns it. The teardown runs detached,
# so this hook returns immediately. Every call is logged with its reason and decision
# to .cks/logs/session-end.log, so it is visible whether the hook fired at all.
input="$(cat 2>/dev/null || true)"
reason="$(printf '%s' "$input" | /usr/bin/plutil -extract reason raw -o - - 2>/dev/null || echo unknown)"
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
mkdir -p .cks/logs
{
  printf '%s SessionEnd reason=%s: ' "$(date '+%Y-%m-%d %H:%M:%S')" "${reason:-unknown}"
  ./cks session-end 2>&1 | tr '\n' ' '
  echo
} >> .cks/logs/session-end.log 2>&1
exit 0
