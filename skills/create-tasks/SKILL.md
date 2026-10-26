---
name: create-tasks
description: >-
  Generate original CKS/CKA/CKAD exam-style practice challenges under sessions/.
  Use when the user invokes /create-tasks or asks to create practice tasks,
  drills, or challenges for Kubestronaut prep.
disable-model-invocation: true
---

# Create tasks

Generate **original** exam-style challenges. Never recreate leaked exam items. Do not write learner answers into `work/`.

## Before generating

1. Read [state/progress.md](../../state/progress.md) for weak domains and avoid-repeats.
2. Re-check live curricula (web or fetch) against [cncf/curriculum](https://github.com/cncf/curriculum) and Linux Foundation CKA/CKAD/CKS pages. Refresh domain names if they changed.
3. Use [reference.md](reference.md) as a **cache** of domain weights — override if the live curriculum differs.
4. Confirm whether the lab is up (`KUBECONFIG=cluster/kubeconfig kubectl cluster-info`). If hands-on tasks need it and it is down, run `cluster/up.sh` (on demand). If that fails (prereqs missing — never install them), continue with file-only tasks and tell the user to see `/setup-cluster`.

## Defaults (ask only if the user did not specify)

| Knob | Default |
|------|---------|
| Count | 3–5 tasks |
| Exam mix | CKS first, then CKA; include 1 CKAD refresh if count ≥ 4 |
| Difficulty mix | At least one `exam`, prefer one `killer` if count ≥ 3; rest `warmup`/`exam` |
| Flavors | Mix ≥ 2 of: greenfield, repair, diagnose, harden, speed |

## Difficulty levels

- **warmup** — single concept, clear requirements, ~5–8 min
- **exam** — multi-step, exam wording, ~10–15 min
- **killer** — multi-object, traps, ambiguous symptoms or harden-on-working-app, ~15–25 min

## Flavors

- **greenfield** — create from scenario
- **repair** — broken YAML in `.meta/seed.yaml` and/or broken live objects; learner fixes in `work/` (and cluster)
- **diagnose** — symptoms only (CrashLoop, DNS, RBAC deny); learner finds and fixes
- **harden** — app works but insecure (CKS); learner locks it down
- **speed** — short timebox; expect imperative kubectl in `work/commands.sh`

## Session layout

Create:

```
sessions/<YYYYMMDD-HHMM>-drill/
  SESSION.md          # short index of tasks
  tasks/
    01-<slug>/
      TASK.md         # from templates/TASK.md — scenario only, NO solutions
      work/.gitkeep
      .meta/rubric.md # from templates/rubric.md — observable checks only
      .meta/seed.yaml # optional; apply if cluster up and flavor needs it
```

Session id: `date + short time + -drill` (e.g. `20260814-1050-drill`).

## TASK.md rules

- Exam voice: concise scenario + numbered requirements.
- Specify namespaces, resource names, images when needed.
- Never include solution YAML, exact one-liner answers, or “hint: use NetworkPolicy”.
- Fill placeholders from [templates/TASK.md](../../templates/TASK.md).

## Rubric rules

- **Observable checks only** (names, ns, labels, probe paths, RBAC verbs, policy selectors).
- No golden full manifests.
- Include `kubectl` verification snippets for live grade.
- List 2 common traps.
- Fill from [templates/rubric.md](../../templates/rubric.md).

## Seeding

If flavor is repair/diagnose/harden and the cluster is available:

1. Write `.meta/seed.yaml` (broken or insecure baseline).
2. If the task needs an add-on (Falco, Gatekeeper, kube-bench, Ingress/Gateway controller), run `cluster/addons.sh <name>` first.
3. Apply with `KUBECONFIG=cluster/kubeconfig kubectl apply -f .meta/seed.yaml`. Node-level seeds (broken apiserver flag, kubelet config) go in via `cluster/node.sh control-plane <cmd>`.
4. Tell the user what was seeded (symptoms), not how to fix it.

If no cluster: still write `seed.yaml` when useful; note “file-only — apply after `/setup-cluster`”.

## Domain weighting (bias selection)

See [reference.md](reference.md). Bias toward weak domains from progress. **CKS is the primary goal**: lead with CKS and keep it tough (supply chain, runtime, microservice vuln, cluster/system harden). CKA second: Troubleshooting and Cluster Architecture.

## Lab limits (CKS)

kind nodes are real kubeadm nodes, so most CKS work is **live** — see the matrix in [cluster/README.md](../../cluster/README.md#live-vs-file-graded).

- **Live:** PSS/PSA, NetworkPolicy, RBAC, SecurityContext, Secrets, ServiceAccount, seccomp (incl. Localhost profiles on nodes), kube-apiserver audit/encryption/admission flags, kubelet config, Ingress TLS / Gateway API (`traefik`), Gatekeeper, kube-bench, Falco, Trivy/kubesec via `cluster/tool.sh`, etcd backup/restore.
- **Node-file tasks** (apiserver manifest, kubelet config, seccomp profiles, audit policy): tell the learner to work on the node like the exam (`cluster/node.sh` or **Attach Shell** in VS Code) and to keep a copy of edited files / commands in `work/` for grading.
- **File-graded only:** AppArmor, gVisor/RuntimeClass handlers, host OS hardening (sysctl, modules, users, packages), OS-package kubeadm upgrades. If `addons.sh falco` fails, Falco tasks are file-graded too.

## After generation

1. Print a short session table: # · slug · exam · domain · difficulty · flavor · time.
2. Point the learner to the first `TASK.md` and `work/`.
3. Remind: `/hint`, `/review`, `/explain-solution` — do not spoil now.
4. Do **not** update progress.md yet (that is `/review`).

## Originality checklist

- [ ] Scenario names/story are unique (not copy-pasted from killer.sh / KodeKloud / leaked PDFs)
- [ ] Requirements match current curriculum (e.g. Gateway API for CKA networking if still listed)
- [ ] No dockershim / removed APIs
- [ ] Rubric has no full solution YAML
