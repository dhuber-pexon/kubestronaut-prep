# Skills (agent workflows)

Tooling-agnostic instructions for any coding agent.

When the learner types a slash command, **open the matching `SKILL.md` and follow it exactly**. That is how sessions get created and how coaching stays consistent.

| Command | Folder | Creates / changes |
|---------|--------|-------------------|
| `/setup-cluster` | [setup-cluster/](setup-cluster/) | Local kind lab (not under `sessions/`) |
| `/create-tasks` | [create-tasks/](create-tasks/) | New `sessions/<id>-drill/` |
| `/exam-session` | [exam-session/](exam-session/) | New `sessions/<id>-exam-…/` |
| `/review` | [review-answer/](review-answer/) | Grades `work/`; updates `state/progress.md` |
| `/hint` | [hint/](hint/) | Progressive hint for an open task |
| `/explain-solution` | [explain-solution/](explain-solution/) | Walkthrough for an open task |

`sessions/` and `state/progress.md` are **gitignored** — generate/update locally. Shared rules: [AGENTS.md](../AGENTS.md). Learner-facing flow: [README.md](../README.md).
