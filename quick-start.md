# Quick start — one full practice cycle

Prerequisite: one-time setup done ([next-steps.md](next-steps.md)). Focus: **CKS first, CKA second**.

```text
open repo → /create-tasks → solve in work/ → /hint ⇄ retry → /review → /explain-solution → exit (lab auto-deleted)
```

## 1. Start

1. Open this repo in VS Code and start Claude Code.
2. Optional: `/setup-cluster` to boot the lab now. Otherwise `/create-tasks` boots it on demand (~1–2 min) when a task needs a live cluster.

## 2. Generate a drill

Pick one:

```text
/create-tasks CKS harden + NetworkPolicy, killer difficulty
/create-tasks CKS supply chain and runtime, 4 tasks
/create-tasks CKA troubleshooting, make them hard
/exam-session                       # full ~2h mock, CKS by default
```

You get `sessions/<id>/tasks/01-…/TASK.md` (read) and `work/` (your answer space). The agent seeds broken/insecure objects and installs add-ons (Falco, Gatekeeper, Traefik, kube-bench) when a task needs them.

## 3. Solve (exam-style)

Work in a VS Code terminal — `KUBECONFIG` already points at the lab.

| Need | Command |
|------|---------|
| Cluster objects | `kubectl …` (try `--dry-run=client -o yaml > work/x.yaml`) |
| Node shell (exam `ssh`) | `./cluster/node.sh` · `./cluster/node.sh worker2` · or *Attach Shell* in the Containers view |
| API server flags / audit / encryption | edit `/etc/kubernetes/manifests/kube-apiserver.yaml` in the control-plane shell; `crictl ps` to watch it restart |
| Kubelet config | `/var/lib/kubelet/config.yaml` on a node, then `systemctl restart kubelet` |
| Seccomp profile | `./cluster/node.sh worker sh -c 'cat > /var/lib/kubelet/seccomp/profiles/p.json' < work/p.json` |
| Image scan | `./cluster/tool.sh trivy image <image>` |
| Manifest risk score | `./cluster/tool.sh kubesec scan work/pod.yaml` |
| Add-on by hand | `./cluster/addons.sh falco` (also `gatekeeper`, `kube-bench`, `traefik`) |
| Lab state | `./cluster/status.sh` |

Rules: answers only in `work/` (YAML, `commands.sh`, copies of node files you edited). Docs: kubernetes.io only, like the real exam. Never peek at `.meta/`.

## 4. Coach loop

| Situation | Say |
|-----------|-----|
| Stuck | `/hint` (3 progressive levels) |
| Done | `/review` — grades `work/` + live cluster, updates `state/progress.md` |
| Want the full walkthrough | `/explain-solution` |
| More practice on weak spots | `/create-tasks` again — it reads your progress |

## 5. Finish

- **Exit Claude Code** (`/exit` or close the panel): the `SessionEnd` hook deletes the cluster and stops the VM in the background. `/clear` does **not** tear down.
- Other agents / manual: `./cluster/down.sh`.
- Keep the lab for the next chat: start Claude Code with `KUBESTRONAUT_KEEP_CLUSTER=1`.
- `sessions/` and `state/` stay on disk (gitignored) — delete old sessions anytime.

## Live vs file-graded

Live: NetworkPolicy, RBAC, PSA, SecurityContext, seccomp, apiserver/kubelet hardening, audit logs, encryption at rest, Ingress TLS, Gateway API, Gatekeeper, Falco, kube-bench, Trivy, kubesec, etcd backup/restore.
File-graded: AppArmor, gVisor/RuntimeClass, host OS hardening. Details: [cluster/README.md](cluster/README.md#live-vs-file-graded).
