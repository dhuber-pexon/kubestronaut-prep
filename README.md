# Kubestronaut practice platform

An **interactive exam gym** for Kubernetes and cloud-native certifications. You practice by solving challenges; an AI coding agent coaches you using the workflows in [`skills/`](skills/).

This is **not** a notes wiki — docs stay on [kubernetes.io](https://kubernetes.io/docs/) and the [CNCF curriculum](https://github.com/cncf/curriculum).

Beginners are welcome: you learn by doing, not by reading a second textbook in this repo.

### Certifications this gym can target

| Cert | Full name | Typical format here |
|------|-----------|---------------------|
| **KCNA** | Kubernetes and Cloud Native Associate | Multiple-choice style drills |
| **KCSA** | Kubernetes and Cloud Native Security Associate | Multiple-choice / conceptual security drills |
| **CKAD** | Certified Kubernetes Application Developer | Hands-on YAML + `kubectl` (refresh OK if you already passed) |
| **CKA** | Certified Kubernetes Administrator | Hands-on cluster admin labs (core focus) |
| **CKS** | Certified Kubernetes Security Specialist | Hands-on security labs (hard mode; some items file-graded on kind/macOS) |

Together, **KCNA + KCSA + CKAD + CKA + CKS** are the path to the CNCF **Kubestronaut** title (all must be active at once). Ask `/create-tasks` with the cert you care about, e.g. “KCSA questions” or “hard CKS harden tasks”.

Related CNCF certs outside that set (Prometheus, Istio, GitOps, …) are optional later — this repo stays focused on the Kubernetes track unless you ask otherwise.

---

## Prerequisites

- A coding agent that can read this repo  
- [kubectl](https://kubernetes.io/docs/tasks/tools/)  
- [kind](https://kind.sigs.k8s.io/) + Docker (recommended for CKA / CKAD / CKS labs)

Associate exams (**KCNA**, **KCSA**) work well without a cluster. Performance exams (**CKAD**, **CKA**, **CKS**) are better with the kind lab.

---

## How it works

```text
/setup-cluster  →  /create-tasks (or /exam-session)
                         │
                         ▼
              sessions/<id>/ appears locally
                         │
                         ▼
              you edit each task’s work/
                    ▲         │
                    │         ▼
                 /hint     /review
                              │
                              └── /explain-solution (when you want the full walkthrough)
```

1. Tell the agent a **skill command** (table below).
2. The agent follows the matching file under [`skills/`](skills/) and (for create/exam) writes a new folder under `sessions/`.
3. You solve only in `work/`.
4. You call `/review`, `/hint`, or `/explain-solution` on that session/task.

**`sessions/` is gitignored.** Your drills and answers stay on your machine. Nothing to commit after practice — generate a fresh session whenever you like.

---

## Skills — what to say to the agent

Any coding agent that reads [`AGENTS.md`](AGENTS.md) should open the skill file and follow it.

| You say | Skill file | What it does |
|---------|------------|--------------|
| `/setup-cluster` | [`skills/setup-cluster/SKILL.md`](skills/setup-cluster/SKILL.md) | Create / destroy / check the local kind lab |
| `/create-tasks` | [`skills/create-tasks/SKILL.md`](skills/create-tasks/SKILL.md) | **Create a short drill session** under `sessions/` |
| `/exam-session` | [`skills/exam-session/SKILL.md`](skills/exam-session/SKILL.md) | **Create a long mock exam session** (~2h) |
| `/review` | [`skills/review-answer/SKILL.md`](skills/review-answer/SKILL.md) | Grade your `work/` (+ cluster if up) |
| `/hint` | [`skills/hint/SKILL.md`](skills/hint/SKILL.md) | One progressive hint (3 levels) |
| `/explain-solution` | [`skills/explain-solution/SKILL.md`](skills/explain-solution/SKILL.md) | Full annotated walkthrough |

You can add plain English, for example:

- `/create-tasks` focus on CKA troubleshooting, make them hard  
- `/create-tasks` KCNA multiple-choice, 5 tasks  
- `/create-tasks` KCSA security concepts  
- `/create-tasks` CKS harden + NetworkPolicy, killer difficulty  
- `/review` task 02 in the latest session  
- `/hint` for harbor-netpol  

---

## Creating a session (step by step)

### 0. Optional lab

```bash
./cluster/up.sh          # or ask: /setup-cluster
./cluster/status.sh
```

Hands-on CKA/CKS tasks are better with a cluster. KCNA-style MCQs work without one.

### 1. Ask the agent to generate work

Say **`/create-tasks`** (short drill) or **`/exam-session`** (full mock).

The agent will:

- Read `state/progress.md` if present (weak topics); otherwise use [`state/progress.example.md`](state/progress.example.md) as empty baseline
- Follow [`skills/create-tasks/SKILL.md`](skills/create-tasks/SKILL.md) (or exam-session)
- Create something like:

```text
sessions/20260921-0915-drill/     # local only (gitignored)
  SESSION.md
  tasks/
    01-some-slug/
      TASK.md          ← read this
      work/            ← you write answers here
      .meta/           ← grading key; agent uses on /review
```

### 2. Solve

- Open `TASK.md` for task `01-…`
- Put answers **only** in that task’s `work/`
  - Hands-on (CKAD / CKA / CKS): YAML and/or `commands.sh` (apply with `kubectl` if you want)
  - Associate (KCNA / KCSA): `answers.md` with lines like `1. B`
- Do not edit `TASK.md`. Do not ask the agent to fill `work/` while you are still solving.

### 3. Coach loop

| Situation | Say |
|-----------|-----|
| Need a nudge | `/hint` |
| Think you are done | `/review` |
| Want the full solution explained | `/explain-solution` |
| Want more practice | `/create-tasks` again (new session folder) |

`/review` updates local `state/progress.md` (gitignored) so later `/create-tasks` can target weak areas. Copy [`state/progress.example.md`](state/progress.example.md) once if the file does not exist yet.

---

## What lives in the repo vs on your disk

| Path | In git? | Purpose |
|------|---------|---------|
| [`skills/`](skills/) | yes | Agent workflows — how to create/review/hint |
| [`AGENTS.md`](AGENTS.md) | yes | Hard rules for every agent |
| [`templates/`](templates/) | yes | Blank TASK + rubric shapes |
| [`cluster/`](cluster/) | yes | kind lab scripts |
| [`state/README.md`](state/README.md) + example | yes | How learner progress works |
| `state/progress.md` | **no** | Your scores / weak domains (local) |
| `sessions/*` | **no** | Generated drills + your answers (local) |
| `cluster/kubeconfig`, `*.kubeconfig` | **no** | Local cluster credentials |

---

## Tips for beginners

1. One task at a time (`01` before `02`).
2. Use https://kubernetes.io/docs/ while solving (same idea as the real exams).
3. Prefer `/hint` → try again → `/review` over jumping to `/explain-solution`.
4. PARTIAL on review is normal — fix `work/` and review again.
5. Delete old `sessions/…` folders anytime; they are disposable. Create new ones with the skills.

---

## Not in scope

- Copying kubernetes.io into markdown files here  
- Leaked real exam items  
- Committing your practice sessions  

**Start:** open a chat on this repo → `/setup-cluster` → `/create-tasks`.
