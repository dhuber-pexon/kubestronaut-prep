# CKS exam gym

A local, disposable practice lab for the **Certified Kubernetes Security Specialist (CKS)** exam, coached by
**Claude Code**. You solve original exam-style challenges in a real Kubernetes v1.37 cluster; Claude generates
the tasks, gives progressive hints, grades your answers and explains solutions.

**→ Just want to start? Read [quick-start.md](quick-start.md).**

- **One dependency:** Podman (free, Apache-2.0). No Docker Desktop, Homebrew, kubectl or kind on your Mac.
- **One entry point:** `./cks` in the VS Code terminal. Start, keep and destroy happen in the background.
- **Strictly local:** nothing is reachable from your network or the internet, and `./cks verify-local` proves it.
- **Private:** nothing outside this folder is changed; everything else lives in a dedicated Podman VM that shares only this folder (plus Podman's own config folder, on Podman 6).
- **Free and open source only:** no accounts, trials, subscriptions or hidden fees.

This is not a notes wiki. Docs stay on [kubernetes.io](https://kubernetes.io/docs/). The curriculum the tasks are built
from is in Markdown in [.claude/skills/create-tasks/reference.md](.claude/skills/create-tasks/reference.md).

---

## How it works

```text
 VS Code terminal                         Claude Code panel
 ────────────────                         ─────────────────
 ./cks ──► Podman VM "cks" (only sees this folder)
             ├─ cks-toolbox   kubectl, kind, trivy, kubesec, kube-linter, cosign, bom, helm
             └─ kind cluster "cks"  (cks-control-plane + cks-worker, Kubernetes v1.37)
 exam shell: k, ssh <node>, vim  ◄────── /create-tasks · /exam-session  → sessions/<id>/
                                         /hint · /grade · /explain-solution
 exit ──► lab destroyed in the background, VM stopped
```

1. `./cks` creates or starts the VM, builds the images (first time only), creates a fresh cluster, seeds your active
   session, runs the local-only audit and opens the exam shell.
2. In the Claude Code panel, run `/create-tasks` or `/exam-session`. Tasks appear under `sessions/` (gitignored).
3. Solve in the exam shell and put your answers in each task's `work/`.
4. `/hint`, `/grade`, `/explain-solution`. `/grade` updates `state/progress.md` (local) so later tasks target your weak domains.
5. `exit` destroys the lab. Next time, `./cks` builds a fresh one.

## Skills

| You type (Claude Code panel) | Does |
|---|---|
| `/create-tasks [count] [topic] [difficulty]` | Short drill (3–5 tasks) under `sessions/` |
| `/exam-session` | 2 h mock exam: 15–16 tasks, 100 points, pass at 67 %, fresh cluster |
| `/hint [task]` | One progressive hint (level 1 → 3) |
| `/grade [task or session]` | Grades `work/` plus read-only live probes; whole sessions are graded in parallel |
| `/explain-solution [task]` | Full annotated walkthrough |

Skill definitions: [.claude/skills/](.claude/skills/). Rules for Claude: [CLAUDE.md](CLAUDE.md).

## `./cks` commands

| Command | Does |
|---|---|
| `./cks` | Start the lab if needed and open the exam shell. Leaving it destroys the lab (`CKS_KEEP=1 ./cks` keeps it). A second `./cks` opens an extra shell. |
| `./cks status` | VM, toolbox, nodes, owner shell, active session |
| `./cks kubectl …` / `./cks k …` | kubectl against the lab |
| `./cks node <node> [-- cmd]` | Shell or command on `cks-control-plane` / `cks-worker` |
| `./cks seed <session or task>` | Make a session active and apply its seeds (or apply them on the next start) |
| `./cks addon falco` | Install Falco (about 30 s; kube-bench is preinstalled on the nodes) |
| `./cks reset [session]` | Fresh cluster, then seed the active (or given) session |
| `./cks up` | Start without a shell |
| `./cks down` | Destroy the cluster and toolbox, stop the VM |
| `./cks purge` | Remove the VM and every cached image (sessions stay) |
| `./cks verify-local` | Prove that nothing is exposed beyond 127.0.0.1 |
| `./cks selftest` | Static checks of the repo: syntax, bash 3.2 pitfalls, guard tests, ShellCheck, privacy (about 10 s; ShellCheck needs the lab) |
| `./cks smoke` | Functional check of the running lab: 18 CKS capabilities and offline tools (about 45 s; cleans up after itself) |

## What is practised live, and what is file-graded

| Live in the lab | File-graded (VM limits) |
|---|---|
| NetworkPolicy, RBAC, ServiceAccounts, Pod Security Admission, securityContext, immutability | AppArmor (the VM kernel has no AppArmor) |
| Secrets + encryption at rest (verified with `etcdctl`) | Running gVisor (RuntimeClass objects are live) |
| seccomp RuntimeDefault / Localhost profiles | Cilium / Istio pod-to-pod encryption |
| kube-apiserver flags: audit policy and log, admission plugins, anonymous auth | kubeadm upgrade |
| kubelet config, kube-bench (CIS) on the nodes | Ingress TLS (spec only, no ingress controller) |
| ValidatingAdmissionPolicy (permitted registries), ImagePolicyWebhook config | |
| trivy, kubesec, kube-linter, bom (SBOM), cosign (local keys) | |
| binary checksum verification, node OS footprint (services, packages, users) | |
| Falco rules and alerts (`./cks addon falco`, modern eBPF) | |

Every row on the left was verified on the real lab: see the results log in [post-podman-steps.md](post-podman-steps.md).

## Local-only and privacy guarantees

- **Structural:** the toolbox publishes no ports. kind publishes only the API server, on `127.0.0.1`.
  The kubeconfig exists only inside the toolbox and points at the internal network. NodePorts and hostPorts stay inside the VM.
- **Audited (fail closed):** every start, and `./cks verify-local`, inspect the port bindings and network mode of **every**
  container in the VM, the folders shared with the VM, and the Mac's listening sockets. Any binding other than `127.0.0.1`,
  or any shared folder other than this one, destroys the lab.
- **Guarded:** a Claude Code hook ([.claude/hooks/guard.sh](.claude/hooks/guard.sh)) blocks commands that would publish ports,
  open tunnels, install software on the Mac or upload project content. Tests: `bash .claude/hooks/test-guards.sh`.
- **Contained:**

  | Where | What |
  |---|---|
  | This folder | `.cks/` (run state, logs), `sessions/`, `state/progress.md`, `.claude/settings.local.json`; all gitignored |
  | Podman VM `cks` | images, cluster, kubeconfig, trivy cache |
  | Outside both | only Podman's own record of the VM (removed by `./cks purge`), plus the one-time macOS folder permission |
  | Never touched | `~/.kube`, `~/.docker`, shell profiles, `/etc`, Homebrew, launchd, keychain |

- **Tools:** trivy's telemetry and version checks are switched off in the toolbox. **cosign** and **kubesec** are offline by default:
  small wrappers make cosign sign with a local signing config (no public transparency log, local keys only) and make kubesec
  validate against JSON schemas bundled in the image instead of downloading them from GitHub. Tested in a container with no network.
- **Claude Code:** project settings deny MCP connectors, Artifacts and reading credential folders (`~/.ssh`, `~/.aws`, `~/.kube`, …),
  ask before web access and before `git push`, and set
  `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` (telemetry, error reporting and auto-update checks off, where your Claude Code
  version honours it in project settings). Claude Code keeps its own conversation history in `~/.claude`; that is outside
  this repo's control.

## Open source components

| Component | Licence | Where it runs |
|---|---|---|
| Podman | Apache-2.0 | Mac (only install) + VM |
| kind, kubectl, Kubernetes, etcd | Apache-2.0 | VM containers |
| trivy, kube-bench | Apache-2.0 | toolbox / nodes |
| kubesec, kube-linter, cosign, bom, helm | Apache-2.0 | toolbox |
| Falco | Apache-2.0 | cluster (on demand) |
| Debian base image | DFSG free licences | toolbox |

Every downloaded binary is pinned to a version and checked against its published sha256
([lab/toolbox/Dockerfile](lab/toolbox/Dockerfile), [lab/node/Dockerfile](lab/node/Dockerfile)).

Docker Desktop is deliberately not used: its licence is free only for some users, it collects usage data by default,
and it shares your whole home folder with its VM. The engine-specific code is one section of `./cks`, if you ever need to switch.

## Repository layout

```
cks                    entry point (macOS bash 3.2, no other dependencies)
quick-start.md         install, prompts, first run, uninstall
CLAUDE.md              rules for Claude Code in this repo
LICENSE.md             licence (PolyForm Noncommercial 1.0.0)
lab/kind.yaml          cluster definition (API on 127.0.0.1, no port mappings)
lab/toolbox/           toolbox image: pinned CLIs, exam bashrc, ssh/sudo shims, teardown
lab/node/              node image: kindest/node v1.37 + vim, etcdctl, kube-bench, docker.io mirror
lab/addons/            Falco values
.claude/settings.json  permissions, hooks, env
.claude/hooks/         session start/end, guards, guard tests
.claude/skills/        /create-tasks, /exam-session, /grade, /hint, /explain-solution
.claude/agents/        cks-grader (read-only grading subagent)
sessions/              your drills and answers (gitignored)
state/                 your progress (gitignored, except the example)
```

## Not in scope

Copying kubernetes.io into this repo, leaked exam items, paid practice platforms, and committing your sessions.

## Licence

PolyForm Noncommercial 1.0.0, see [LICENSE.md](LICENSE.md): free for personal study, learning, research and
non-profit use. Commercial use (e.g. paid trainings) needs permission from the authors.
The tools the lab downloads keep their own open source licences (see [Open source components](#open-source-components)).
