# Local kind lab (Podman, no Docker)

kind nodes (real kubeadm: systemd, kubelet, static pods, etcd) run as containers inside a dedicated rootful **Podman machine** named `kubestronaut`. No Docker Desktop. The lab is **ephemeral**: Claude Code tears it down when the session ends.

| Script | Purpose |
|--------|---------|
| `up.sh` | Start the `kubestronaut` machine, create cluster `kubestronaut` (1 control-plane + 2 workers) |
| `down.sh [--keep-machine]` | Delete the cluster, remove the kubeconfig, stop the machine |
| `status.sh` | Machine state, nodes, namespaces, installed add-ons |
| `addons.sh <name>…` | CKS add-ons on demand: `falco`, `gatekeeper`, `kube-bench`, `traefik` (Ingress + Gateway API) |
| `tool.sh <tool> …` | CKS CLIs as throwaway containers: `trivy`, `kubesec` |
| `node.sh [node] [cmd…]` | The exam's `ssh <node>`: shell/command on `control-plane`, `worker`, `worker2` |
| `session-end.sh` | Claude Code `SessionEnd` hook → background `down.sh` (log: `cluster/down.log`) |
| `kind.yaml` | kind config, node image pinned to the CKS exam version |
| `lib.sh` | Shared settings (sourced) |

```bash
./cluster/up.sh
export KUBECONFIG=$PWD/cluster/kubeconfig   # automatic in VS Code terminals of this workspace
./cluster/status.sh
./cluster/down.sh
```

Requires (one-time, see [README → One-time Mac setup](../README.md#one-time-mac-setup)): `podman`, `kind`, `kubectl`, and the `kubestronaut` podman machine. Scripts start/stop that machine but never create or delete it.

## Sandboxing

What stays isolated:

- Everything Kubernetes runs **inside the `kubestronaut` VM** (Apple Hypervisor framework via vfkit/krunkit, runs as your user — no root on the Mac). Images, add-ons, Trivy cache and node disks live on the VM disk.
- The VM sees only this repo, **read-only** (`--volume "$PWD:$PWD:ro"` at init). The default `$HOME` share is not mounted.
- The kubeconfig lives only in `cluster/kubeconfig` (gitignored, mode 600) — `~/.kube/config` is never read or written.
- All script podman/kind calls are pinned to the lab machine via `CONTAINER_CONNECTION=kubestronaut-root`.
- `down.sh` deletes the cluster and stops the VM; nothing keeps running in the background.

Residual exposure (by design of Podman on macOS — know it, don't worry about it):

- Pods can reach the internet and services listening on your Mac's `localhost` (via `host.containers.internal`). Don't run sensitive local services during deliberately-insecure CKS drills.
- Privileged pods (common in CKS "harden this" seeds) can escape to the kind node and the VM — but stop there: the VM has only the read-only repo mount.
- One-time footprint outside the repo: Homebrew packages, `~/.config/containers/`, `~/.local/share/containers/` (VM image + disk, several GB). Removal: see [next-steps.md](../next-steps.md#uninstall).

**Keep the lab after the session:** start Claude Code with `KUBESTRONAUT_KEEP_CLUSTER=1`. `/clear` and `/resume` do not trigger teardown.

**Node shell (exam `ssh`):** `cluster/node.sh` (control plane) or `cluster/node.sh worker|worker2`, or **Attach Shell** in the VS Code Containers view.

## Live vs file-graded

| Live in this lab | File-graded only |
|------------------|------------------|
| NetworkPolicy, RBAC, ServiceAccounts, PSA/PSS, SecurityContext, Secrets | AppArmor (the Podman VM is SELinux-based Fedora CoreOS) |
| seccomp RuntimeDefault + Localhost profiles (copy into `/var/lib/kubelet/seccomp/profiles/` on a node) | gVisor / RuntimeClass handlers (no `runsc` in nodes) |
| kube-apiserver hardening via `/etc/kubernetes/manifests/kube-apiserver.yaml`: audit policy + log, encryption at rest, admission plugins, anonymous-auth | Host OS hardening: sysctl, kernel modules, users, packages |
| kubelet config + `systemctl restart kubelet` on a node | kubeadm upgrade via OS packages |
| Ingress TLS / Gateway API (`addons.sh traefik`), Gatekeeper, kube-bench, Falco*, Trivy, kubesec | |
| CKA: etcd backup/restore, static-pod and kubelet troubleshooting, drain/taints | |

\* Falco needs a modern-eBPF capable VM kernel. If `addons.sh falco` fails, Falco tasks are file-graded (rules files + sample events).
