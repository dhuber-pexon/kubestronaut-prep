---
name: create-tasks
description: Generate a short drill of original CKS exam-style challenges under sessions/. Use when the learner runs /create-tasks or asks for CKS practice tasks, drills or challenges.
argument-hint: "[count] [domain or topic] [warmup|exam|killer]"
disable-model-invocation: true
---

# Create tasks (CKS drill)

Learner request: **$ARGUMENTS**

Generate **original** CKS exam-style challenges. Never recreate leaked exam items or copy scenarios
from paid practice platforms. Never write learner answers into `work/`.

## Before generating

1. Read `state/progress.md` if it exists (weak domains, avoid repeats). If it doesn't, use `state/progress.example.md` as an empty baseline.
2. Use [reference.md](reference.md) as the **authoritative** CKS curriculum (v1.37) and domain weights.
   Do **not** browse the web to refresh it unless the learner asks for a refresh.
3. Lab state comes from the SessionStart line, or run `./cks status --brief`. Never start the lab yourself:
   seeds are applied now if the lab runs, otherwise automatically when the learner runs `./cks`.

## Defaults (ask only if the request leaves them open and the choice matters)

| Knob | Default |
|---|---|
| Count | 3–5 tasks |
| Domains | Weighted by reference.md, biased toward weak domains in progress.md |
| Difficulty mix | ≥ 1 `exam`; ≥ 1 `killer` if count ≥ 3; the rest `warmup`/`exam` |
| Flavors | Mix ≥ 2 of: greenfield, repair, diagnose, harden, investigate, speed |

**Difficulty:** `warmup` = one concept, about 5 min · `exam` = multi-step, exam wording, about 8–12 min ·
`killer` = several objects, traps, or hardening a working app, about 12–20 min.

**Flavors:** `greenfield` build from a scenario · `repair` fix seeded broken objects or node config ·
`diagnose` symptoms only · `harden` lock down a working but insecure app · `investigate` find the culprit
(audit log, Falco alert, rogue process or user) and act · `speed` short timebox, imperative commands.

## Session layout

```
sessions/<YYYYMMDD-HHMM>-drill/
  SESSION.md                 # index: # · slug · domain · difficulty · flavor · time · points · live/file
  tasks/
    01-<slug>/
      TASK.md                # from templates/TASK.md: scenario only, NO solution
      given/                 # optional starter files (Dockerfile, broken manifest, audit-log excerpt, …)
      work/.gitkeep          # empty: the learner's space
      .meta/rubric.md        # from templates/rubric.md: observable checks only
      .meta/seed.sh          # optional, from templates/seed.sh: idempotent lab setup
```

- Starter files go in `given/`, **never** in `work/`.
- Use distinct namespaces per task (e.g. `t01-<word>`), so tasks don't interfere.

## TASK.md rules

- Exam voice: short scenario plus numbered, verifiable requirements. Name the namespaces, objects, nodes, file paths and images.
- For node work, say which node and how to reach it: `ssh cks-control-plane` / `ssh cks-worker` in the exam shell.
- Never include solution YAML, exact one-liners, or hints such as "use a NetworkPolicy".
- Images must be open source, small and pinned: `registry.k8s.io/…`, official Docker Hub images such as
  `nginx:1.29-alpine`, `busybox:1.37`, `alpine:3.22`. **Never Bitnami** (paywalled) and nothing that needs a login.
- Tooling must be what the lab ships: kubectl, trivy, kubesec, kube-linter, cosign (local keys only), bom, helm (template only),
  etcdctl and kube-bench (on the nodes), Falco (`./cks addon falco`). Nothing needs an account or licence.
- Local only: tasks never publish ports, use `hostNetwork` toward the outside, or upload anything (no public Rekor/tlog,
  no online scanners such as the kubesec.io API).

## Rubric rules

- Observable checks with points; no golden manifests.
- Live probes are single `./cks kubectl …` / `./cks node <node> -- …` commands that only read
  (get, describe, auth can-i, grep, cat, ls, crictl ps / inspect). The cks-grader subagent can run nothing else.
- Mark file-graded items explicitly (AppArmor, gVisor runtime, Cilium/Istio encryption, kubeadm upgrade).
- List 2 common traps.

## Seeding

For `repair` / `diagnose` / `harden` / `investigate` flavors, write `.meta/seed.sh` from
[templates/seed.sh](templates/seed.sh). It must be **idempotent**, because it re-runs after every fresh cluster.
It may run node commands via `ssh <node> '<cmd>'`, e.g. weaken an apiserver flag, install a rogue package, or drop an
unwanted user. Make it executable.

Then run, in the background (the first lab start can take minutes):

```bash
./cks seed sessions/<id>
```

It makes the session active. If the lab runs, it seeds now; otherwise the seeds run automatically when the
learner starts `./cks`. Report what was seeded as **symptoms only**. Never fix a seed failure by hand; fix `seed.sh`.

## After generation

1. Print the session table (# · slug · domain · difficulty · flavor · time · live/file).
2. Point to the first `TASK.md`, and say: run `./cks` in the VS Code terminal if it isn't running.
3. Remind the learner of `/hint`, `/grade` and `/explain-solution`. Don't spoil anything now.
4. Don't update `state/progress.md` yet; `/grade` does that.

## Originality checklist

- [ ] Unique scenario names and story (not from killer.sh, KodeKloud, Udemy or leaked dumps)
- [ ] Matches the v1.37 curriculum in reference.md; no removed APIs (PodSecurityPolicy, dockershim, …)
- [ ] Rubric has no full solution
- [ ] Only free, open-source images and tools; nothing exposed beyond the lab
