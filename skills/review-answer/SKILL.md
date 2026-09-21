---
name: review-answer
description: >-
  Grade Kubestronaut practice answers in work/ against .meta/rubric.md and
  optional live kubectl state. Use when the user invokes /review or /review-answer
  or asks to check, grade, or validate their task solution.
disable-model-invocation: true
---

# Review answer

Grade the learner’s work. **Do not dump a full solution** — that is `/explain-solution`.

## Scope

1. If the user names a task path, review that task.
2. Else if they name a session, review all tasks in that session.
3. Else ask which `sessions/.../tasks/...` to review (or review the most recent unfinished session).

## Allowed reads

- `TASK.md`
- `work/**`
- `.meta/rubric.md` (and `.meta/seed.yaml` if needed to understand baseline)
- `state/progress.md` (to update after grade)

Do **not** edit `work/` or `TASK.md`.

## Procedure

1. Read `TASK.md` and `.meta/rubric.md`.
2. Inspect all files under `work/` (YAML + `commands.sh`).
3. Cluster check: run `kubectl cluster-info` (timeout short). If healthy, run the rubric’s kubectl probes. If down, file-grade only and say so.
4. Score each must-pass and nice-to-have item: **pass** / **fail** / **unclear**.
5. Overall:
   - **PASS** — all must-pass met
   - **PARTIAL** — some must-pass met
   - **FAIL** — little or no must-pass met

## Output format

```markdown
## Review: <task slug>

**Result:** PASS | PARTIAL | FAIL
**Mode:** files + cluster | files only

### Must-pass
- [x] ... — evidence
- [ ] ... — what’s missing (no full fix)

### Nice-to-have
- ...

### Exam efficiency
- Faster approach / imperative shortcut (high level)
- Namespace / naming / API version nits

### Next
- Retry this task, or `/hint`, or `/explain-solution` if stuck
```

## Feedback rules

- Point to **what failed** and **which requirement** — not paste the complete fixed YAML.
- One short “direction” tip is OK (“check the NetworkPolicy `podSelector` matches the frontend labels”).
- Flag deprecated APIs and wrong namespaces.
- Praise correct must-pass items briefly.

## Update progress

Append/update [state/progress.md](../../state/progress.md):

- Session/task, exam, domain, result, date
- Add failing domains under **Weak domains**
- Add theme/slug under **Avoid repeats**
- Adjust **Notes for next generate**

## Multi-task / exam session

If reviewing a full `/exam-session`:

1. Grade each task with the format above (can be compact).
2. Compute weighted score from rubric points.
3. Write/update `sessions/<id>/SESSION.md` scoring sheet (points earned / possible, domain breakdown).
4. Still no golden solutions in SESSION.md.
