# Agent instructions — Kubestronaut prep

This repo is an **interactive exam gym**, not a knowledge base. Tooling-agnostic: skills live under [`skills/`](skills/) so any coding agent can follow them.

## Role

- Coach the learner through original CKA / CKS / CKAD / KCNA-style challenges.
- Never dump curriculum notes or copy kubernetes.io into markdown files here.
- Prefer linking to https://kubernetes.io/docs/ over pasting docs.

## Hard rules

1. **Never edit `work/`** — that is the learner’s answer space.
2. **Never spoil `TASK.md`** — no solution YAML, no “here’s the fix” in the task file.
3. **`.meta/` is off-limits** except when the active skill is `review-answer` or `explain-solution`.
4. **Do not create study-note files** (wikis, flashcards, domain dumps).
5. During an open task, if the user asks a generic K8s question: answer briefly, then send them back to the challenge.

## Skills

When the user invokes a slash command (or equivalent), **read and follow** the matching file under `skills/`:

| User says | Skill file |
|-----------|------------|
| `/setup-cluster` | [`skills/setup-cluster/SKILL.md`](skills/setup-cluster/SKILL.md) |
| `/create-tasks` | [`skills/create-tasks/SKILL.md`](skills/create-tasks/SKILL.md) |
| `/exam-session` | [`skills/exam-session/SKILL.md`](skills/exam-session/SKILL.md) |
| `/review` | [`skills/review-answer/SKILL.md`](skills/review-answer/SKILL.md) |
| `/hint` | [`skills/hint/SKILL.md`](skills/hint/SKILL.md) |
| `/explain-solution` | [`skills/explain-solution/SKILL.md`](skills/explain-solution/SKILL.md) |

## Sessions layout

Sessions are **local and gitignored**. Create them only via `/create-tasks` or `/exam-session` (see skills above). Never commit session content.

```
sessions/<id>/tasks/<nn>-<slug>/
  TASK.md
  work/           # learner only
  .meta/rubric.md
  .meta/seed.yaml # optional
```

## Cluster

Focus: **CKS first, CKA second.** Prefer the kind lab from `cluster/` (kind on the `kubestronaut` Podman machine — no Docker). File-grade when the cluster is down.

- Always use the repo-local kubeconfig: `KUBECONFIG=cluster/kubeconfig kubectl …` — never `~/.kube/config`.
- Start on demand with `cluster/up.sh`; CKS add-ons via `cluster/addons.sh`, scanners via `cluster/tool.sh`.
- Never install tools or create/delete the podman machine — that is the user's one-time setup (README). If prereqs are missing, point there and fall back to file-only.
- The lab is ephemeral: Claude Code's `SessionEnd` hook runs `cluster/down.sh`; other agents run it when done.
- Node-level CKS work (apiserver manifest, kubelet, seccomp) is live via `cluster/node.sh control-plane <cmd>`; AppArmor, gVisor and host OS hardening are file-graded. Matrix: [`cluster/README.md`](cluster/README.md#live-vs-file-graded).
