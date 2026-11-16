---
name: grade
description: Grade the learner's CKS task answers in work/ against .meta/rubric.md, plus read-only probes of the live lab when it runs. Use when the learner runs /grade or asks to check, grade or validate a task or a whole session.
argument-hint: "[sessions/<id> | sessions/<id>/tasks/<nn-slug> | task number]"
disable-model-invocation: true
---

# Grade

Target: **$ARGUMENTS**

Grade the learner's work. **Never paste a full solution**; that is `/explain-solution`.

## Scope

1. A task path or task number → that task, in the most recent session if no session is named.
2. A session path → every task in it (an exam session is scored as a whole).
3. Nothing given → the most recent session's first task with a non-empty `work/`, or ask.

## Allowed

- Read `TASK.md`, `given/**`, `work/**`, `.meta/rubric.md`, `.meta/seed.sh`, and `state/progress.md`.
- Run read-only live probes from the rubric through `./cks kubectl …` and `./cks node <node> -- …`.
- **Never** edit `work/`, `TASK.md` or `given/`. Never change the cluster while grading; no apply, delete or edit.
- Never start the lab. If it isn't running (check the SessionStart line or `./cks status --brief`), grade from files only and say so.

## Single task

1. Read `TASK.md`, then `.meta/rubric.md`.
2. Inspect everything under `work/` (manifests, `commands.sh`, saved copies of node files).
3. If the lab runs, execute the rubric's live probes one by one.
   - A probe that finds no object, while the matching file in `work/` is correct, usually means the lab was
     rebuilt since the learner applied it. Mark the item **unclear**, and tell them to re-apply `work/` and `/grade` again.
4. Mark each item **pass** / **fail** / **unclear** with evidence (file and line, or probe output).
5. Result: **PASS** (all must-pass items), **PARTIAL** (some), **FAIL** (none or almost none). Points as in the rubric.

## Whole session / mock exam

Delegate: start one **cks-grader** subagent per task, **in parallel** (one message, several Agent calls).
Give each the task path and whether the lab is running. Then merge their verdicts, compute the total out of 100
(pass at 67), fill the scoring sheet and the domain breakdown in `sessions/<id>/SESSION.md`, and report.
Never put solutions into `SESSION.md`.

## Output (per task)

```markdown
## Grade: <nn-slug> — PASS | PARTIAL | FAIL (<earned>/<possible> pts)
**Mode:** files + live lab | files only

### Must-pass
- [x] … (evidence)
- [ ] … (what is missing, not how to fix it)

### Nice-to-have
- …

### Exam efficiency
- faster approach in one line; namespace or API-version nits

### Next
- retry, `/hint`, or `/explain-solution`
```

## Feedback rules

- Point at the failed requirement, not at the fixed YAML. One direction tip is fine
  ("compare the policy's podSelector with the frontend's labels").
- Flag removed or deprecated APIs and wrong namespaces.
- Credit correct items briefly.

## Update progress

Create or update `state/progress.md` (start from `state/progress.example.md`). Record:
- date, session/task, domain, result and points
- failing domains under **Weak domains**
- the task theme under **Avoid repeats**
- a line under **Notes for next generate**

Nothing in it may leave the machine: it is gitignored and stays local.
