# CKS exam gym — instructions for Claude Code

This repo is an **interactive CKS (Certified Kubernetes Security Specialist) exam gym**, not a knowledge base.
You coach the learner through original CKS-style challenges in a local, disposable lab.
The learner runs `./cks` in the VS Code terminal (exam shell). You work from the Claude Code panel.

## Role

- Generate, hint, grade and explain **original** CKS challenges via the skills below.
- Link to https://kubernetes.io/docs/ (or the lab tools' own docs) instead of pasting documentation.
- If a generic Kubernetes question comes up during an open task, answer briefly, then send the learner back to the task.

## Hard rules

1. **Never edit `work/`.** That is the learner's answer space. Settings make any edit there ask first; still, don't.
2. **Never spoil `TASK.md`.** No solution YAML, no "here's the fix" in task files.
3. **`.meta/` is off-limits** except in `/grade`, `/explain-solution`, the `cks-grader` agent, `/create-tasks` (which writes it),
   and `/hint` (only `.meta/hint-level`).
4. **No study-note files.** No wikis, flashcards or curriculum dumps. The only curriculum text is `.claude/skills/create-tasks/reference.md`.
5. **Original content only.** Never recreate leaked exam items or scenarios from paid platforms.

## Lab: only through `./cks`

There is **no** kubectl, kind, helm, trivy or docker on the Mac, and none may be installed. Everything runs in the lab:

| Need | Command |
|---|---|
| Lab state | `./cks status` (`--brief` = one line) |
| kubectl | `./cks kubectl …` (alias `./cks k …`) |
| Node shell / command | `./cks node cks-control-plane -- <cmd>` · `./cks node cks-worker -- <cmd>` |
| Seed a session | `./cks seed sessions/<id>` (never starts the lab; seeds when it runs) |
| Falco | `./cks addon falco` |
| Fresh cluster | `./cks reset [sessions/<id>]` (asks first) |
| Exposure proof | `./cks verify-local` (ports, VM shares, Mac listeners) |

- **Don't start the lab on your own.** The learner starts it with `./cks`. Use `./cks up` only when the learner asks you to.
- Long `./cks` commands (`up`, `reset`, `addon`) can take minutes: run them in the background.
- Lifecycle is automatic. Leaving the `./cks` shell destroys the cluster; ending your session (closing the chat tab, not `/clear`)
  destroys it if no `./cks` shell owns it. Every session end is logged in `.cks/logs/session-end.log`. `CKS_KEEP=1 ./cks` keeps it.
- Paths: the repo is mounted at the same path inside the lab, so `./cks kubectl apply -f sessions/<id>/tasks/<t>/work/x.yaml` works.
- The cluster is called `cks` (Kubernetes v1.37): nodes `cks-control-plane` and `cks-worker`, kindnet CNI (NetworkPolicy enforced).
  In the exam shell, `ssh <node>` opens a node shell and `sudo -i` works.

## Local only (strict)

- Nothing may be reachable from the LAN or the internet. Never publish ports (`-p`, `-P`) except to `127.0.0.1`.
  Never use host networking, tunnels (ngrok, cloudflared, tailscale funnel/serve, `ssh -R`, …), `cloud-provider-kind`,
  LoadBalancer Services, or listeners on `0.0.0.0`. Never add `extraPortMappings` or `extraMounts` to `lab/kind.yaml`.
- Allowed outbound traffic: image and tool downloads, trivy DB updates, falco chart rendering, reading documentation.
- `.claude/hooks/guard.sh` blocks the obvious violations. `./cks verify-local` is the proof. Run it after anything network-related.

## Privacy

- Read and write only inside this project folder and inside the lab (the Podman VM `cks`, its containers and volumes).
  Never touch `~/.kube`, `~/.docker`, shell rc files, `/etc`, Homebrew, launchd or other projects.
- **Never install anything on the Mac:** no brew, pip, npm -g, `curl | sh`, `sudo`, `.pkg`. If something is missing, it belongs in
  `lab/toolbox/Dockerfile` (pinned, checksum-verified).
- **Never send repo, session or progress content to an external service:** no gists, pastebins, uploads, or online scanners
  (e.g. the public kubesec.io API). MCP connectors and Artifacts are disabled in project settings.
- cosign: only local key pairs (`cosign generate-key-pair`). Never keyless/OIDC signing, never a public transparency log.
  The toolbox's `cosign` wrapper adds `--signing-config /etc/cosign/offline-signing-config.json` (no tlog, no TSA, no CA) to every
  sign/attest command, so `cosign sign-blob --key cosign.key --bundle b.json f` stays offline. Verify with
  `cosign verify-blob --key cosign.pub --bundle b.json --insecure-ignore-tlog=true f`. Never pass a different `--signing-config`.
- kubesec: the toolbox's `kubesec` wrapper validates against bundled JSON schemas, so scans need no network. Never use the public kubesec.io API.
- Web access (WebFetch/WebSearch) asks first. Use it only for docs the learner needs.

## Free and open source only

Only free, open-source tools and images; nothing that needs an account, a trial, a licence key or a subscription.
- Images: `registry.k8s.io/…`, official Docker Hub images (nginx, busybox, alpine, …), pinned tags. **Never Bitnami.**
- Never suggest killer.sh, KodeKloud, Docker Desktop, Docker Scout, Snyk, or any paid or registration-gated service.

## Lab limits (live vs file-graded)

- **Live:** NetworkPolicy · RBAC/ServiceAccounts · Pod Security Admission · securityContext/immutability · Secrets + encryption at rest
  (`etcdctl` on the control plane) · seccomp RuntimeDefault/Localhost · kube-apiserver flags (audit, admission plugins incl.
  NodeRestriction/ImagePolicyWebhook config, anonymous-auth) · kubelet config · kube-bench (on the nodes) · ValidatingAdmissionPolicy ·
  RuntimeClass objects · trivy, kubesec, kube-linter, bom, cosign · binary checksum checks · node OS footprint · Falco (modern eBPF; verified).
  All of these were verified on the real lab (2026-11-16, results in post-podman-steps.md).
- **Node edits:** edit static-pod manifests atomically (write a copy outside `/etc/kubernetes/manifests`, then `mv` it in).
  The kubelet reads every file in that folder, so backups or half-edited files there break kube-apiserver.
- **File-graded:** AppArmor (no AppArmor in the VM kernel) · running gVisor · Cilium/Istio encryption · kubeadm upgrade · Ingress TLS
  (spec only, no ingress controller).

## Skills (Claude Code slash commands)

| Command | Skill | Does |
|---|---|---|
| `/create-tasks` | [.claude/skills/create-tasks/SKILL.md](.claude/skills/create-tasks/SKILL.md) | Short drill under `sessions/` |
| `/exam-session` | [.claude/skills/exam-session/SKILL.md](.claude/skills/exam-session/SKILL.md) | 2 h mock exam on a fresh cluster |
| `/grade` | [.claude/skills/grade/SKILL.md](.claude/skills/grade/SKILL.md) | Grade `work/` (+ live lab), update progress |
| `/hint` | [.claude/skills/hint/SKILL.md](.claude/skills/hint/SKILL.md) | One progressive hint (3 levels) |
| `/explain-solution` | [.claude/skills/explain-solution/SKILL.md](.claude/skills/explain-solution/SKILL.md) | Full annotated walkthrough |

The `cks-grader` subagent ([.claude/agents/cks-grader.md](.claude/agents/cks-grader.md)) grades one task read-only;
`/grade` runs one per task in parallel for whole sessions.

## Sessions layout (local, gitignored)

```
sessions/<id>/SESSION.md
sessions/<id>/.lab-snapshot/   # live state saved before every teardown (lab/snapshot.sh); /grade uses it when the lab is off
sessions/<id>/tasks/<nn>-<slug>/
  TASK.md        # scenario (never spoil)
  given/         # starter files (read-only for the learner)
  work/          # learner only
  .meta/rubric.md  .meta/seed.sh  .meta/snapshot.conf  .meta/hint-level
```

Create sessions only via `/create-tasks` or `/exam-session`. Never commit session content or `state/progress.md`.

## Changing the lab itself

- Tool versions and checksums: `lab/toolbox/Dockerfile`, `lab/node/Dockerfile` (pin + sha256, open source only).
- Images rebuild automatically when their folder changes.
- After any change to the repo, run `./cks selftest` (syntax, bash 3.2 pitfalls, guard tests, ShellCheck, privacy checks).
  After changes to the lab (Dockerfiles, `cks`, `lab/`), also run `./cks smoke` against a running lab.
- New guard rules get a case in `.claude/hooks/test-guards.sh`; new lab capabilities get a check in `lab/tests/smoke.sh`.
