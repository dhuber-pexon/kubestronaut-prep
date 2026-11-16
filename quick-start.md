# Quick start

The short version: **install Podman once, then run `./cks`.** Everything else happens automatically.

## What you need

| Item | What it means for you |
|---|---|
| **Install (once)** | **Podman**: download `podman-installer-macos-arm64.pkg` from the official releases page, https://github.com/podman-container-tools/podman/releases (latest stable release, not an `-rc`), and run it. The installer asks for your macOS admin password once. This is the **only** install. Podman is free and open source (Apache-2.0). |
| **Skip the installer's last step** | The installer ends by suggesting `podman machine init`. **Don't run it**: `./cks` creates its own VM. That default VM (`podman-machine-default`) would share your whole `/Users` folder. If you already ran it, remove it: `podman machine rm podman-machine-default`. |
| **Remove the extra helper (recommended)** | The installer also adds `podman-mac-helper`, a root background service that points the standard Docker socket at Podman. The lab doesn't use it. Remove it with `sudo /opt/podman/bin/podman-mac-helper uninstall` (reinstall anytime with `… install`). A leftover socket file in `/var/run` disappears at the next reboot. |
| **Already in place** | VS Code with the Claude Code extension, signed in to your existing Claude account. That is the only account involved; this project doesn't create one. |
| **Accounts, logins, tokens** | **None.** No Docker Hub, GitHub, registry, Linux Foundation or cloud login, and no API keys. Images and tools are downloaded anonymously. |
| **Possible macOS prompt** | On the first start, macOS **may** ask whether Podman's VM helper (shown as *krunkit* or *vfkit*) may access files in your **Documents** folder. Click **Allow**. Started from the VS Code terminal there is usually no prompt, because VS Code already has that access. Either way, the VM shares **only this project folder**, and that is checked on every start. |
| **Internet** | First run: about 2–3 GB (VM image, toolbox, Kubernetes node image). Later: only task images and trivy database updates. Outbound downloads only; nothing is exposed. |
| **Disk / RAM / CPU** | The VM grows to about 15–20 GB (40 GB max) and uses 4 CPUs and 6 GB RAM, **only while the lab runs**. |

Not needed: Docker Desktop, Homebrew, kubectl, kind, helm, trivy, Python packages, or any extra VS Code extension.

## Start practising

1. Open this folder in VS Code and open the terminal (`` Ctrl+` ``).
2. Run:
   ```bash
   ./cks
   ```
   The first run takes about 4–10 minutes, depending on your connection (measured: about 4 minutes): the VM is created and the
   images are built. Later starts take about 1 minute (measured: 48 s), because the images stay cached in the VM.
   You end up in the **exam shell** (`cks:…$`), which has `kubectl` (alias `k`), completion, vim, trivy, kubesec, kube-linter, cosign and bom.
3. In the **Claude Code panel**, type `/create-tasks`, for example `/create-tasks 3 tasks, audit logs and NetworkPolicies, hard`,
   or `/exam-session` for a 2-hour mock exam.
4. Open the task's `TASK.md` and solve it in the exam shell:
   - `cd sessions/<id>/tasks/01-…` and put your manifests and commands into `work/`
   - node work as in the exam: `ssh cks-control-plane` (or `ssh cks-worker`), then `sudo -i`
5. Coach loop in the Claude Code panel: `/hint` → try again → `/grade` → `/explain-solution` if you're stuck.

## Stopping

- Type `exit` (or `logout`) in the exam shell and confirm (Enter = yes). The lab is **destroyed** in the background and the VM
  stops within about 20 seconds.
  Your `sessions/` and `state/` files stay. Closing the terminal tab does the same.
- `n` at the prompt takes you back to the shell. Ctrl-D is ignored ("Use logout to leave the shell"), so you can't leave by accident.
- `CKS_KEEP=1 ./cks` keeps the lab running after you leave. Destroy it later with `./cks down`.
- Starting again with `./cks` builds a fresh cluster and re-applies the seeds of your active session. Re-apply your `work/`
  if you want to `/grade` live state again.

## Nothing to do (automatic)

Creating, starting and stopping the VM, the lab network, the images, the cluster, the kubeconfig, seeding and teardown are all
handled by `./cks` inside the VM. Nothing is written to `~/.kube`, `~/.docker` or your shell profile.

## Troubleshooting

| Symptom | Do |
|---|---|
| Something looks off | `./cks status` |
| Want proof nothing is exposed | `./cks verify-local` |
| Cluster broken beyond repair (e.g. kube-apiserver won't come back) | `./cks reset` |
| "The VM cannot read this project folder" | System Settings → Privacy & Security → Files and Folders → allow the Podman VM helper, then `./cks` |
| "Another Podman VM is running" | `podman machine list`, then stop the other one with `podman machine stop <name>` |
| Logs | `.cks/logs/` (machine, build, cluster, seed, teardown) |
| More commands | `./cks help` |

## Uninstall

1. `./cks purge` removes the VM, all lab images and caches, and `.cks/`. Your `sessions/` stay.
2. If still installed, remove the helper: `sudo /opt/podman/bin/podman-mac-helper uninstall`.
3. Uninstall Podman: run `/opt/podman/bin/podman-uninstall` if your release ships it, or delete `/opt/podman` and `/etc/paths.d/podman-pkg` (admin rights needed).
4. Delete this folder if you're done.
