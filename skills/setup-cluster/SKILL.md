---
name: setup-cluster
description: >-
  Create or destroy the local kind multi-node lab (on Podman) for Kubestronaut
  hybrid practice. Use when the user invokes /setup-cluster or asks to start,
  stop, recreate, or check the practice Kubernetes cluster or its CKS add-ons.
disable-model-invocation: true
---

# Setup cluster

Manage the local **kind** lab used for hybrid (files + live) practice. kind nodes run inside the dedicated rootful Podman machine `kubestronaut` — no Docker.

## Scripts

| Action | Command |
|--------|---------|
| Create | `cluster/up.sh` |
| Destroy | `cluster/down.sh` (add `--keep-machine` to leave the VM running) |
| Status | `cluster/status.sh` |
| CKS add-ons | `cluster/addons.sh falco\|gatekeeper\|kube-bench\|traefik` |
| CKS CLIs | `cluster/tool.sh trivy\|kubesec …` |

All scripts live under [cluster/](../../cluster/). Prefer running them over reinventing kind/podman commands. kubectl always targets the repo-local kubeconfig: `KUBECONFIG=cluster/kubeconfig kubectl …`.

## Prerequisites (user-prepared — never install)

`podman`, `kind`, `kubectl` on PATH and the podman machine `kubestronaut` (see [README → One-time Mac setup](../../README.md#one-time-mac-setup)). If anything is missing, the scripts say so: relay the README pointer. **Do not** run `brew install`, `podman machine init`, or `podman machine rm` yourself.

## Procedure

### Create / recreate

1. If the cluster already exists, ask before deleting, or recreate if the user said “recreate” (`cluster/down.sh --keep-machine && cluster/up.sh`).
2. Run `bash cluster/up.sh` (starts the machine if stopped; first run pulls the node image).
3. Verify: `KUBECONFIG=cluster/kubeconfig kubectl get nodes` → 1 control-plane + 2 workers Ready.
4. Install add-ons only if the user asked (or a task needs one).
5. Summarize lab limits (below) and next step: `/create-tasks` or `/exam-session`.

### Destroy

1. Run `bash cluster/down.sh`.
2. Confirm cluster gone, `cluster/kubeconfig` removed, machine stopped.

### Status

1. Run `bash cluster/status.sh`.
2. Report machine state, Ready nodes, installed add-ons.

## Lifecycle (tell the user once per setup)

- The lab is **ephemeral**: in Claude Code a `SessionEnd` hook ([.claude/settings.json](../../.claude/settings.json)) runs `cluster/down.sh` in the background when the session exits. `/clear` and `/resume` keep it.
- Keep it across sessions: start Claude Code with `KUBESTRONAUT_KEEP_CLUSTER=1`.
- Other agents: run `cluster/down.sh` when done.

## Lab limits (tell the user once per setup)

See the matrix in [cluster/README.md](../../cluster/README.md#live-vs-file-graded). Short version:

- **Live:** NetworkPolicy, RBAC, PSA, SecurityContext, seccomp (incl. Localhost profiles on nodes), kube-apiserver flags/audit/encryption/admission via the static-pod manifest, kubelet config, Ingress TLS/Gateway API (`traefik`), Gatekeeper, kube-bench, Falco (if kernel supports it), Trivy/kubesec, etcd backup/restore.
- **File-graded:** AppArmor, gVisor/RuntimeClass handlers, host OS hardening, OS-package kubeadm upgrades.
- Node access like the exam: `cluster/node.sh` or **Attach Shell** in VS Code.
- Per-task namespaces keep isolation; `/create-tasks` should use distinct ns names.

## Do not

- Install anything on the Mac, or create/delete the podman machine.
- Install a kitchen-sink platform (Istio, full observability stack) unless the user asks.
- Commit kubeconfigs with credentials (`cluster/kubeconfig` is gitignored).
- Spoil or generate tasks unless the user also asked for that.
