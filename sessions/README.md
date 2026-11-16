# Sessions (local only)

Your CKS drills and answers live here. **This folder is gitignored** (`sessions/*` except this README),
so nothing you practise is committed or leaves your machine.

Don't create session folders by hand. In the Claude Code panel:

- `/create-tasks` creates a short drill
- `/exam-session` creates a 2-hour mock exam

Then solve in each task's `work/` from the exam shell (`./cks`), and use `/hint`, `/grade` or `/explain-solution`.

```text
sessions/<id>/
  SESSION.md
  tasks/
    01-<slug>/
      TASK.md     # read this
      given/      # starter files (don't edit)
      work/       # your answers (+ copies of files you changed on a node)
      .meta/      # rubric and seed, used by /grade (don't peek)
```

Delete old session folders whenever you like.
