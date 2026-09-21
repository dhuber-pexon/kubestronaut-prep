---
name: hint
description: >-
  Give progressive, non-spoiling hints for an open Kubestronaut practice task.
  Use when the user invokes /hint or asks for a hint without wanting the full
  solution.
disable-model-invocation: true
---

# Hint

Progressive assistance only. **Never jump to level 3** on the first request for a task.

## Scope

Identify the task (`sessions/.../tasks/...`). If unclear, ask or use the most recently discussed open task.

## Allowed reads

- `TASK.md`
- `work/**` (to see how far they got)
- Hint level state: if present, `.meta/hint-level` (create/update as `1`, `2`, or `3`)

**Do not read `.meta/rubric.md`** for hints (avoids accidental spoilers). Infer from TASK.md + work/.

**Do not edit `work/` or `TASK.md`.**

## Levels (strict order)

### Level 1 — domain / object

- Which Kubernetes area or resource kind(s) matter
- What to look up on kubernetes.io (topic, not the answer page dump)
- Example: “This is a networking isolation problem between two workloads in the same namespace.”

### Level 2 — fields / flags

- Which fields, labels, or kubectl verb families to focus on
- Still no complete command or full YAML
- Example: “Your policy’s `podSelector` and the frontend Pod labels need to agree; also check `ingress.from`.”

### Level 3 — almost the command

- Near-complete imperative sketch or YAML skeleton with intentional blanks
- Still not a paste-ready full solution
- Example: `kubectl create ... --dry-run=client -o yaml` shape with one critical value left for the learner

## Escalation

1. Read `.meta/hint-level` if it exists; else start at 1.
2. Deliver **only** the next level (or the current level if they ask to repeat).
3. Write `.meta/hint-level` with the level you just gave.
4. If already at 3 and they ask again: remind them of `/explain-solution` or `/review` — do not invent a “level 4” full dump.

## Tone

- Short (≤ 8 lines).
- No shame. Exam prep is iterative.
- End with: “Try again in `work/`, then `/hint` for the next level or `/review` when ready.”
