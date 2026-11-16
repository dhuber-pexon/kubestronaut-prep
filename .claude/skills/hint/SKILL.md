---
name: hint
description: Give one progressive, non-spoiling hint (level 1, then 2, then 3) for an open CKS practice task. Use when the learner runs /hint or asks for a nudge without the full solution.
argument-hint: "[task number or slug]"
disable-model-invocation: true
---

# Hint

Task: **$ARGUMENTS** (if empty: the task currently being discussed, else the most recent session's first open task)

Progressive help only. **Never jump to level 3** on the first request for a task.

## Allowed

- Read `TASK.md`, `given/**` and `work/**` (to see how far the learner got).
- Read and write `.meta/hint-level` (`1`, `2` or `3`). That is the only `.meta/` file a hint touches.
- Read-only lab look-ups are fine when they help you aim the hint (`./cks kubectl get …`).
- **Do not read `.meta/rubric.md` or `.meta/seed.sh`** (no accidental spoilers). Don't edit `work/`, `TASK.md` or `given/`.

## Levels (strict order)

1. **Area:** which Kubernetes or security area and which object kinds matter; what to search for on kubernetes.io
   (a topic, not the answer page). E.g. "This is about restricting what the API server accepts at admission time."
2. **Fields / flags:** which fields, flags, files or tools to focus on, without a full command or YAML.
   E.g. "Look at the kube-apiserver manifest on the control plane: which flag points to an audit policy, and where must the file be mounted?"
3. **Almost the command:** a skeleton with an intentional blank (`kubectl create … $do`, a YAML outline
   with the critical value left out). Still not paste-ready.

## Escalation

1. Read `.meta/hint-level`; start at 1 if it's missing.
2. Give **only** the next level (or repeat the current one if asked).
3. Write the level you gave to `.meta/hint-level`.
4. At level 3 already: point to `/grade` or `/explain-solution`. There is no level 4.

## Tone

At most 8 lines, no judgement. End with: "Try again in `work/`, then `/hint` for the next level or `/grade` when ready."
