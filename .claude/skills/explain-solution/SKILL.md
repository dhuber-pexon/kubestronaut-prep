---
name: explain-solution
description: Walk through a full, annotated solution for a CKS practice task, covering why it works, its exam relevance and faster exam techniques. Use when the learner runs /explain-solution or explicitly asks for the walkthrough.
argument-hint: "[task number or slug]"
disable-model-invocation: true
---

# Explain solution

Task: **$ARGUMENTS** (ask if ambiguous)

Full coaching walkthrough. Best **after** an attempt or a FAIL/PARTIAL grade. If the learner clearly wants the
answer now, go ahead.

## Allowed

- Read `TASK.md`, `given/**`, `work/**`, `.meta/rubric.md` and `.meta/seed.sh`.
- Read-only lab probes via `./cks kubectl …` / `./cks node <node> -- …` to contrast expected and actual state.
- **Do not edit `work/`.** If the learner asks to keep the explanation, write it to `<task>/solution.md`
  (next to `TASK.md`, never inside `work/`). By default, the explanation stays in chat.

## Output

```markdown
## Solution: <nn-slug>

### What the exam is testing
- CKS domain and competency (from reference.md), and why it matters in practice

### Approach
1. Steps in exam-efficient order (what to check first, where to verify)
2. Imperative vs YAML, and when to work on a node (`ssh cks-control-plane`, `sudo -i`)

### Annotated manifests / commands
- Complete working YAML and/or commands, commented where non-obvious
- Which rubric must-pass item each part satisfies
- Node edits: the exact file, the changed lines, and how to confirm that the component restarted

### Why this design
- The security rationale, and alternatives that would fail the rubric

### Faster exam technique
- `k … $do`, `kubectl explain --recursive`, `crictl ps` / `crictl logs` when the API server is down, backup copies before node edits

### Common traps
- From the rubric, plus what you saw in their `work/`

### Docs
- 1–3 specific kubernetes.io (or tool docs) links, no pasted chapters
```

## Rules

- Teach, don't just paste: every major block gets a "why".
- Don't create knowledge-base or notes files in the repo.
- Suggest a fresh, similar task via `/create-tasks <domain>` for spaced practice.
- Optionally note in `state/progress.md` that this domain was explained (not passed).
