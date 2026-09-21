# Sessions (local only)

Generated drills and your answers live here. **This directory is gitignored** (`sessions/*` except this README).

Do not create session folders by hand. Ask an agent:

- `/create-tasks` — short drill → follows [`skills/create-tasks/SKILL.md`](../skills/create-tasks/SKILL.md)
- `/exam-session` — long mock → follows [`skills/exam-session/SKILL.md`](../skills/exam-session/SKILL.md)

Then solve under each task’s `work/`, and use `/hint`, `/review`, or `/explain-solution`.

```text
sessions/<id>/
  SESSION.md
  tasks/
    01-slug/
      TASK.md
      work/       # you
      .meta/      # rubric for /review
```

You can delete old session folders anytime and generate new ones.
