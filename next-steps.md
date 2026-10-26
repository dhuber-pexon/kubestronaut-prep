# Next steps

One-time checklist to go from "repo cloned" to "lab verified". The repo never installs software or creates the VM for you — these steps are yours. Daily usage afterwards: [quick-start.md](quick-start.md).

## 1. Install the tools (≈ 5 min)

```bash
brew install podman kind kubectl
```

All three are Apache-2.0 and free. No Docker Desktop, Podman Desktop, Helm, Trivy or kubesec install needed.

Optional — only for `cluster/tool.sh kubesec` (its image is x86-only and gets emulated on Apple silicon):

```bash
softwareupdate --install-rosetta --agree-to-license   # free, from Apple; skip if already installed
```

## 2. Create the lab VM (≈ 3 min)

Run from the **repo root**, in a regular terminal:

```bash
cd /path/to/kubestronaut-prep
podman machine init kubestronaut --rootful --cpus 4 --memory 8192 --disk-size 50 \
  --volume "$PWD:$PWD:ro"
```

- The name `kubestronaut` is fixed — the scripts look for it.
- `--volume "$PWD:$PWD:ro"` means the VM sees only this repo, read-only (not your home directory).
- If asked whether to make it the default connection: either answer works (the scripts pin the connection themselves).
- Don't start it — `cluster/up.sh` starts and stops it.
- Lower on RAM? `--memory 6144` works for the base cluster; Falco + Gatekeeper together want 8 GB.

## 3. Wire up the editor and agent

1. Reload the VS Code window (Command Palette → *Developer: Reload Window*). Workspace settings now point **Container Tools** at Podman and the **Kubernetes** extension + integrated terminals at `cluster/kubeconfig`.
2. In Claude Code, run `/hooks` once and confirm the `SessionEnd` hook from `.claude/settings.json` is listed (it runs `cluster/session-end.sh`).

## 4. First run — verify the lab

Do these in a VS Code terminal in this repo. Each line says what "good" looks like.

| # | Command | Expected |
|---|---------|----------|
| 1 | `./cluster/up.sh` | First run pulls the node image (~1 GB), then 3 nodes `Ready`, version `v1.34.11` |
| 2 | `kubectl get nodes` | Same 3 nodes (terminal already has `KUBECONFIG` set) |
| 3 | `ls ~/.kube/config` | Unchanged / still absent — the lab never writes there |
| 4 | `./cluster/node.sh control-plane ls /etc/kubernetes/manifests` | `etcd.yaml kube-apiserver.yaml …` (static pods) |
| 5 | `./cluster/addons.sh gatekeeper` | Rollouts complete, "gatekeeper: ready" |
| 6 | `./cluster/addons.sh traefik` | "traefik: ready" |
| 7 | `./cluster/addons.sh kube-bench` | CIS report for master + node printed |
| 8 | `./cluster/addons.sh falco` | "falco: ready" — **or** a clear "modern eBPF unsupported" message (then Falco tasks are file-graded) |
| 9 | `./cluster/tool.sh trivy image nginx:1.25` | Vulnerability table |
| 10 | `./cluster/tool.sh trivy k8s --report summary` | Cluster summary (checks the VM → API server path) |
| 11 | `./cluster/tool.sh kubesec scan <some pod.yaml in the repo>` | JSON score (needs Rosetta/emulation) |
| 12 | VS Code **Containers** view | 3 `kubestronaut-*` containers; *Attach Shell* opens a node shell |
| 13 | VS Code **Kubernetes** view | Lab cluster with nodes/namespaces |
| 14 | `./cluster/down.sh` | Cluster deleted, `cluster/kubeconfig` gone, machine stopped. Run again → instant no-op |
| 15 | `./cluster/up.sh`, then exit Claude Code (`/exit`) | `cluster/down.log` shows teardown; `podman machine list` → stopped |
| 16 | `./cluster/up.sh`, then `/clear` in Claude Code | Cluster still running |

Items 7, 8, 10, 11 could not be tested before your setup — if one fails, ask the agent with the error output and it will patch the script.

## 5. Commit

```bash
git add -A && git commit -m "Docker-free ephemeral kind lab on Podman, CKS-first"
```

## Good to know

- **Docker Hub rate limits:** anonymous pulls are rate-limited per IP. If pulls fail with `toomanyrequests`, log in with a free account: `podman login docker.io` (stored in `~/.config/containers/auth.json`, never in the repo).
- **Keep the lab across chats** (e.g. a 2h mock exam spanning sessions): start Claude Code with `KUBESTRONAUT_KEEP_CLUSTER=1`, and run `./cluster/down.sh` yourself afterwards.
- **Another Podman machine running?** Stop it first — macOS runs one at a time.
- **Moved the repo?** Recreate the machine (the read-only mount points at the old path).

## Uninstall

```bash
./cluster/down.sh                                   # if the lab is running
podman machine rm -f kubestronaut                   # VM + its disk and image cache
brew uninstall podman kind kubectl
rm -rf ~/.config/containers ~/.local/share/containers   # only if you use Podman for nothing else
```
