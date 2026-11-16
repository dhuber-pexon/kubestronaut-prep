#!/bin/bash
# SessionStart: tell Claude, in one line, what state the lab is in. Read-only; never starts anything.
cat >/dev/null 2>&1 || true   # hook input is not needed
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
./cks status --brief 2>/dev/null || echo "CKS lab: status unavailable (run ./cks status)."
exit 0
