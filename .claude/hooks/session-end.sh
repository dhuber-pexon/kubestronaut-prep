#!/bin/bash
# SessionEnd (not on /clear or resume; see the matcher in settings.json):
# destroy the lab unless a ./cks terminal still owns it. The teardown runs detached,
# so this hook returns immediately.
cat >/dev/null 2>&1 || true
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
./cks session-end >/dev/null 2>&1 || true
exit 0
