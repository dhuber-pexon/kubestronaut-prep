---
name: exam-session
description: Create a timed CKS mock exam (15–16 tasks, 2 hours, 100 points, 67 % to pass) under sessions/, on a fresh lab cluster. Use when the learner runs /exam-session or asks for a full CKS mock exam.
argument-hint: "[focus or difficulty, optional]"
disable-model-invocation: true
---

# Exam session (CKS mock)

Learner request: **$ARGUMENTS**

Build a full CKS mock under `sessions/`. Generate every task with the **create-tasks** rules:
[../create-tasks/SKILL.md](../create-tasks/SKILL.md), [../create-tasks/reference.md](../create-tasks/reference.md) and
the templates in [../create-tasks/templates/](../create-tasks/templates/).

## Defaults

| Knob | Default |
|---|---|
| Duration | 2 hours (remind the learner; there is no enforced timer) |
| Tasks | 15–16 |
| Points | 100 total, 4–9 per task, like the real exam |
| Pass mark | 67 % |
| Kubernetes | v1.37 (the lab version) |

## Domain mix (points ≈ weight)

Cluster Setup 15 · Cluster Hardening 15 · System Hardening 10 · Minimize Microservice Vulnerabilities 20 ·
Supply Chain Security 20 · Monitoring, Logging and Runtime Security 20.

Include ≥ 3 repair/diagnose, ≥ 2 harden, ≥ 1 investigate and ≥ 2 killer tasks, plus ≥ 2 node-level tasks
(apiserver manifest, kubelet, seccomp, audit). Keep file-graded items to ≤ 2 tasks.

## Procedure

1. Read `state/progress.md` and bias toward weak domains; avoid recent slugs.
2. Create `sessions/<YYYYMMDD-HHMM>-exam/` with `SESSION.md` and `tasks/01-…` to `tasks/16-…`. Each task is
   built exactly as in create-tasks (`TASK.md`, `given/`, empty `work/`, `.meta/rubric.md`, optional `.meta/seed.sh`).
3. Fresh cluster, like the real exam. Check the lab state (SessionStart line or `./cks status --brief`):
   - **Lab running:** run `./cks reset sessions/<id>` in the background. It asks for permission; it recreates the
     cluster and seeds every task of this session.
   - **Lab not running:** run `./cks seed sessions/<id>`. The learner's next `./cks` builds a fresh cluster and seeds it.
   If a seed fails, report which task is affected; don't block the session.
4. Write `SESSION.md` (template below). **No solutions.**

## SESSION.md template

```markdown
# CKS mock exam: <id>

**Tasks:** N · **Timebox:** 2 h · **Points:** 100 · **Pass:** 67 · **Kubernetes:** v1.37
**Created:** <ISO date> · **Lab:** fresh cluster | seeded on next ./cks

## Rules (exam-like)

- Work in the exam shell (`./cks`); node access via `ssh cks-control-plane` / `ssh cks-worker`
- Put answers in each task's `work/` (plus copies of changed node files)
- Docs: kubernetes.io/docs, kubernetes.io/blog, and the docs of the lab's tools
- No peeking at `.meta/` until after `/grade`
- Flag hard tasks and come back; don't sink 20 minutes into one

## Tasks

| # | Slug | Domain | Diff | Flavor | Pts | Time | Grading |
|---|------|--------|------|--------|-----|------|---------|
| 1 | … | | | | | | live/file |

## Scoring sheet (filled by /grade)

| # | Result | Earned | Possible |
|---|--------|--------|----------|
| 1 | — | — | |

**Total:** — / 100 · **Result:** —

## Domain breakdown (filled by /grade)
```

## After creation

1. Show the task table and the timing advice (skip a task after 2× its suggested time).
2. Tell the learner: run `./cks` in the VS Code terminal and start with `tasks/01-…/TASK.md`.
3. When done: `/grade sessions/<id>` scores the whole exam.
4. Don't grade or explain anything now.
