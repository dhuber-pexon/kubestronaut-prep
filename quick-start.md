# Quick start

**Short version:** install Podman once, then run `./cks` in the VS Code terminal, then type `/exam-session`
(or `/create-tasks`) in the Claude Code panel.

Everything runs locally in a private VM that can only see this folder. Nothing is reachable from your network,
and no account is needed besides your Claude account.

## One-time setup

1. **Install Podman**, the only install. Download `podman-installer-macos-arm64.pkg` from
   https://github.com/podman-container-tools/podman/releases (the latest stable release, not an `-rc`) and run it.
   It asks for your macOS admin password once.
2. **Skip the installer's last step** (`podman machine init`): `./cks` creates its own VM. If you already ran it,
   remove that default VM, because it shares your whole `/Users` folder:
   ```bash
   podman machine rm podman-machine-default
   ```
3. **Recommended:** remove the helper service the installer adds. The lab doesn't use it.
   ```bash
   sudo /opt/podman/bin/podman-mac-helper uninstall
   ```
4. Open this folder in VS Code with the Claude Code extension, signed in to your Claude account.

| Good to know | |
|---|---|
| Accounts, logins, tokens | **None** besides your Claude account. Images and tools are downloaded anonymously. |
| macOS prompt | On the first start, macOS **may** ask whether *krunkit* or *vfkit* may access your Documents folder: click **Allow**. From the VS Code terminal there is usually no prompt. |
| Internet | The first start downloads a few GB (VM, tools, Kubernetes). Later only task images and scanner updates. Outbound only. |
| Resources | 4 CPUs and 6 GB RAM, **only while the lab runs**. The VM disk can grow up to 40 GB. |

## Every time you practise

### 1. Start the lab

Open the VS Code terminal (`` Ctrl+` ``) and run:

```bash
./cks
```

- The first start takes about 4–10 minutes (the VM and images are built once). Later starts take about 1 minute.
- You land in the **exam shell** (`cks:…$`): `k` is kubectl (with completion); vim, trivy, kubesec, kube-linter, cosign
  and bom are installed. Node access works as in the exam: `ssh cks-control-plane` or `ssh cks-worker`, then `sudo -i`.
- Keep this terminal open while you practise.

### 2a. Mock exam (2 hours)

1. In the Claude Code panel, type `/exam-session`.
2. **Approve the permission prompt for `./cks reset`.** It gives you a fresh cluster, like the real exam. Your exam shell stays open.
3. Wait for the task table. Generating 15–16 tasks takes a few minutes.
4. **Note the time: you have 2 hours.** No timer is enforced. Work through the tasks in the Explorer under
   `sessions/<id>/tasks/01-…`, `02-…` and so on. If a task takes about twice its suggested time, skip it and come back later.
5. When you're done: `/grade sessions/<id>`. You get a score out of 100; the pass mark is 67.

Docs allowed, as in the real exam: https://kubernetes.io/docs/ and the docs of the lab's tools.

### 2b. Short drill

Type `/create-tasks` with what you want to practise, for example `/create-tasks 3 tasks, audit logs and NetworkPolicies, hard`.

### 3. Solve tasks

- Read each task's `TASK.md`, and don't edit it.
- Work in the exam shell. Save every manifest and command in that task's **`work/`** folder (for example `work/commands.sh`).
  After editing a file on a node, also save a copy of it in `work/`.
- Coach loop in the Claude Code panel: `/hint` (3 levels, one at a time), then `/grade`, then `/explain-solution` if you're stuck.
  `/grade 02` grades task 02 of the latest session.

### 4. Stop

- Type `exit` in the exam shell and press Enter. The lab is destroyed in the background and the VM stops (about 20 s).
  Your `sessions/` and `state/` folders stay.
- **Always `exit` before quitting VS Code.** Quitting directly is safe, but it skips saving your live work for `/grade`.
- `n` at the "destroy?" prompt takes you back to the shell. Ctrl-D does nothing, so you can't leave by accident.
  `CKS_KEEP=1 ./cks` keeps the lab running after you leave; stop it later with `./cks down`.

**After you stop:**
- `/grade` still works. Your live state was saved to `sessions/<id>/.lab-snapshot/` (Secret values and keys are never saved).
- The next `./cks` gives you a fresh cluster with the starting state of your tasks. To continue live work, re-apply your
  manifests in the exam shell, e.g. `k apply -f sessions/<id>/tasks/<task>/work/netpol.yaml`. Apply only your manifests,
  not the copies of node files, and redo node edits by hand.

## Troubleshooting

| Symptom | Do |
|---|---|
| `Podman is not installed` right after installing it | Open a new terminal, so it picks up Podman's path |
| "Found a leftover cluster from an earlier session; rebuilding it fresh" | Nothing: that's the expected cleanup after quitting VS Code without `exit` |
| Something looks off | `./cks status` |
| You want proof that nothing is exposed | `./cks verify-local` |
| Cluster broken beyond repair (e.g. kube-apiserver won't come back) | `./cks reset` |
| "The VM cannot read this project folder" | System Settings → Privacy & Security → Files and Folders → allow the Podman VM helper, then `./cks` |
| "Another Podman VM is running" | `podman machine list`, then `podman machine stop <name>` |
| Logs | `.cks/logs/` |
| All commands | `./cks help` |

## Uninstall

1. `./cks purge` removes the VM, all lab images and caches, and `.cks/`. Your `sessions/` stay.
2. If still installed, remove the helper: `sudo /opt/podman/bin/podman-mac-helper uninstall`.
3. Uninstall Podman: run `/opt/podman/bin/podman-uninstall` if your release ships it, or delete `/opt/podman` and
   `/etc/paths.d/podman-pkg` (admin rights needed).
4. Delete this folder if you're done.
