---
name: exam-session
description: >-
  Create a timed CKA/CKS/CKAD-style mock exam session (~15–17 tasks, ~2h) with
  domain-weighted mix and scoring sheet. Use when the user invokes /exam-session
  or asks for a full mock exam or timed practice.
disable-model-invocation: true
---

# Exam session

Build a full mock under `sessions/`. Reuse the generation rules from the **create-tasks** skill ([../create-tasks/SKILL.md](../create-tasks/SKILL.md) and [../create-tasks/reference.md](../create-tasks/reference.md)).

## Defaults

| Knob | Default |
|------|---------|
| Duration | 2 hours (remind user; agent does not enforce a timer) |
| Task count | 15–17 |
| Points | ~100 total (vary per task 2–8 like real exams) |
| Exam | Ask once: `cka` · `cks` · `ckad` · `mixed` (default **mixed**: CKA+CKS heavy, 2–3 CKAD) |

## Domain mix targets

**CKA mock:** weight tasks ≈ Troubleshooting 30%, Arch/Install 25%, Networking 20%, Workloads 15%, Storage 10%.

**CKS mock:** ≈ Microservice vuln 20%, Supply chain 20%, Runtime/logging 20%, Cluster setup 15%, Cluster harden 15%, System harden 10% (system harden mostly file-grade).

**CKAD mock:** per CKAD weights in create-tasks reference.

**Mixed (default):** ~8 CKA · ~6 CKS · ~2–3 CKAD; include ≥3 diagnose/repair and ≥2 harden; ≥2 killer difficulty.

## Procedure

1. Read `state/progress.md`; bias weak domains; avoid recent slugs.
2. Web-check current curriculum if stale vs create-tasks reference.
3. Create:

```
sessions/<YYYYMMDD-HHMM>-exam-<cka|cks|ckad|mixed>/
  SESSION.md
  tasks/
    01-<slug>/ ... 17-<slug>/
```

4. For each task: same as create-tasks (`TASK.md`, empty `work/`, `.meta/rubric.md`, optional `seed.yaml`).
5. Seed live cluster only for tasks that need it — and only if kubectl works. Don’t block the whole session on seed failures; note which tasks need manual apply.
6. Write `SESSION.md` (template below). **No solutions.**

## SESSION.md template

```markdown
# Exam session: <id>

**Mode:** <cka|cks|ckad|mixed> · **Tasks:** N · **Timebox:** 2h · **Points:** 100
**Started:** <ISO date> · **Cluster:** up|down

## Rules (exam-like)

- Work only in each task’s `work/`
- Docs allowed: kubernetes.io (and man pages) — treat this like PSI
- No peeking at `.meta/` until after `/review`
- Move on if stuck; mark and return

## Task list

| # | Slug | Exam | Domain | Diff | Flavor | Pts | Time |
|---|------|------|--------|------|--------|-----|------|
| 1 | ... | | | | | | |

## Scoring sheet (fill via /review)

| # | Result | Earned | Possible |
|---|--------|--------|----------|
| 1 | — | — | |

**Total:** — / 100

## Domain breakdown (after review)

_Filled by review-answer._
```

## After creation

1. Show the task table and suggested timeboxing (e.g. skip after 2× suggested time).
2. Tell the user to start with `tasks/01-.../TASK.md`.
3. When done: `/review` on the session path for full scoring.
4. Do not grade now. Do not explain solutions now.

## Originality

Same hard rule as create-tasks: original scenarios only; no leaked exam recreation.
