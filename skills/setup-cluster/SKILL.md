---
name: setup-cluster
description: >-
  Create or destroy the local kind multi-node lab for Kubestronaut hybrid
  practice. Use when the user invokes /setup-cluster or asks to start, stop,
  recreate, or check the practice Kubernetes cluster.
disable-model-invocation: true
---

# Setup cluster

Manage the local **kind** lab used for hybrid (files + live) practice.

## Scripts

| Action | Command |
|--------|---------|
| Create | `cluster/up.sh` |
| Destroy | `cluster/down.sh` |
| Status | `cluster/status.sh` |

All scripts live under [cluster/](../../cluster/). Prefer running them over reinventing kind commands.

## Procedure

### Create / recreate

1. Ensure `docker` (or kind-supported runtime) and `kind` + `kubectl` are on PATH.
2. If a cluster named `kubestronaut` already exists, ask before deleting, or use recreate if the user said “recreate”.
3. Run `bash cluster/up.sh`.
4. Verify: `kubectl get nodes` → 1 control-plane + 2 workers Ready.
5. Summarize limits (below) and next step: `/create-tasks` or `/exam-session`.

### Destroy

1. Run `bash cluster/down.sh`.
2. Confirm kind cluster `kubestronaut` is gone.

### Status

1. Run `bash cluster/status.sh` (or `kubectl get nodes,ns` if context is set).
2. Report Ready nodes and current context.

## Lab limits (tell the user once per setup)

- **macOS + kind:** no real AppArmor / full kubelet host harden — those CKS items are **file-graded**.
- Prefer in-cluster tasks: NetworkPolicy, RBAC, PSS, SecurityContext, Secrets, probes, Deployments, Services.
- Ingress/Gateway live checks need a controller; without one, treat Ingress/Gateway as file-grade unless the user installs one.
- Per-task namespaces keep isolation; `/create-tasks` should use distinct ns names.

## Do not

- Install a kitchen-sink platform (Istio, full observability stack) unless the user asks.
- Commit kubeconfigs with credentials (`cluster/kubeconfig` is gitignored).
- Spoil or generate tasks unless the user also asked for that.
