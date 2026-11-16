# Rubric: {{NN}} {{TITLE}}

> Observable checks only, never a golden manifest dump.
> Read only by /grade, /explain-solution and the cks-grader subagent.

| Field | Value |
|---|---|
| Domain | {{DOMAIN}} |
| Difficulty | {{DIFFICULTY}} |
| Flavor | {{FLAVOR}} |
| Points | {{POINTS}} |
| Grading | live + files · files only |

## Must-pass

- [ ] {{CHECK_1}}  ({{PTS}} pts)
- [ ] {{CHECK_2}}  ({{PTS}} pts)
- [ ] {{CHECK_3}}  ({{PTS}} pts)

## Nice-to-have

- [ ] {{NICE_1}}

## Live probes (read-only; run only if the lab is up)

```bash
# One probe per line, each a single ./cks command (pipes into grep/head/wc are fine).
# ./cks kubectl -n <ns> get networkpolicy <name> -o jsonpath='{.spec.podSelector}'
# ./cks kubectl auth can-i delete pods --as system:serviceaccount:<ns>:<sa> -n <ns>
# ./cks node cks-control-plane -- grep -- '--audit-log-path' /etc/kubernetes/manifests/kube-apiserver.yaml
```

## File checks (always)

- Expected kinds / names / namespaces under `work/`
- Copies of changed node files present in `work/` (node tasks)
- No deprecated or removed APIs for Kubernetes v1.37

## Common traps

- {{TRAP_1}}
- {{TRAP_2}}

## Efficiency notes (coach after grading)

- Imperative shortcuts (`k create … $do`), order of operations, what to verify before moving on
