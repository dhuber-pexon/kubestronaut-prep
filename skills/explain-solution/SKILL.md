---
name: explain-solution
description: >-
  Explain a full annotated solution for a Kubestronaut practice task: why the
  approach works, exam relevance, and faster techniques. Use when the user
  invokes /explain-solution or explicitly wants the walkthrough after attempting.
disable-model-invocation: true
---

# Explain solution

Full coaching walkthrough. Prefer this **after** the learner tried (or after FAIL/PARTIAL review). If they clearly want the answer now, proceed.

## Scope

Target one `sessions/.../tasks/...` (ask if ambiguous).

## Allowed reads

- `TASK.md`, `work/**`, `.meta/rubric.md`, `.meta/seed.yaml`
- Live cluster via kubectl if useful to contrast expected vs actual

**Do not edit `work/`** unless the user explicitly asks you to apply a fix (default: explain only, leave their files alone).

## Output structure

```markdown
## Solution: <slug>

### What the exam is testing
- Domain + why it matters for CKA/CKS/CKAD
- Weight / related curriculum angle (1–2 lines)

### Approach
1. Ordered steps (exam-efficient order)
2. When to use imperative vs YAML

### Annotated manifests / commands
- Complete working YAML and/or commands
- Inline comments on non-obvious fields
- Call out must-pass rubric items satisfied

### Why this design
- Security / reliability / ops rationale (esp. CKS)
- Alternatives and when they’d fail the rubric

### Faster PSI-console technique
- Imperative one-liners, `--dry-run=client -o yaml`, bookmarks

### Common traps
- From the rubric + extras you see in their work/

### Docs
- 1–3 kubernetes.io links (specific paths), not a pasted chapter
```

## Rules

- Teach; don’t only paste. Every major block gets a “why”.
- Link docs; **do not** create new knowledge-base files in the repo.
- Optional: offer a `work/solution-reference.yaml` **only if the user asks** to save a reference (default: keep explanation in chat).
- After explaining, suggest a fresh similar task via `/create-tasks` targeting the same domain for spaced practice.
- Optionally note in `state/progress.md` that this domain was reviewed with a full explain (not a PASS).
