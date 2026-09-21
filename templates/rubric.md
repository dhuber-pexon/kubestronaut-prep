# Rubric: {{TITLE}}

> Observable checks only — not a golden YAML dump.
> Agent: use during `/review` and `/explain-solution` only.

## Identity

| Field | Value |
|-------|-------|
| Exam | {{EXAM}} |
| Domain | {{DOMAIN}} |
| Difficulty | {{DIFFICULTY}} |
| Flavor | {{FLAVOR}} |
| Points | {{POINTS}} |

## Must-pass

- [ ] {{CHECK_1}}
- [ ] {{CHECK_2}}
- [ ] {{CHECK_3}}

## Nice-to-have

- [ ] {{NICE_1}}

## kubectl verification (when cluster available)

```bash
# Example probes — replace with task-specific commands
# kubectl get -n <ns> ...
```

## File checks (always)

- Expected resource kinds / names under `work/`
- Correct namespace, labels, selectors as required
- No deprecated APIs for the current exam k8s version

## Common failure modes

- {{TRAP_1}}
- {{TRAP_2}}

## Efficiency notes (coach after grade)

- Imperative shortcuts the learner could have used
- Order of operations that saves exam time
