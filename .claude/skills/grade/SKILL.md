---
name: grade
description: Grade the learner's CKS task answers in work/ against .meta/rubric.md, plus read-only probes of the live lab when it runs. Use when the learner runs /grade or asks to check, grade or validate a task or a whole session.
argument-hint: "[sessions/<id> | sessions/<id>/tasks/<nn-slug> | task number]"
disable-model-invocation: true
---

# Grade

Target: **$ARGUMENTS**

Grade the learner's work. **Never paste a full solution**; that is `/explain-solution`.

## Scope

1. A task path or task number → that task, in the most recent session if no session is named.
2. A session path → every task in it (an exam session is scored as a whole).
3. Nothing given → the most recent session's first task with a non-empty `work/`, or ask.

## Allowed

- Read `TASK.md`, `given/**`, `work/**`, `.meta/rubric.md`, `.meta/seed.sh`, `state/progress.md`, and the session's
  `.lab-snapshot/**` (live state saved when the lab was last torn down; see below).
- Run read-only live probes from the rubric through `./cks kubectl …` and `./cks node <node> -- …`.
- **Never** edit `work/`, `TASK.md` or `given/`. Never change the cluster while grading; no apply, delete or edit.
- Never start the lab. Check its state first (SessionStart line or `./cks status --brief`).

## Evidence sources, in this order

1. **Lab running** → live probes ("Mode: files + live lab").
2. **Lab not running, `sessions/<id>/.lab-snapshot/` exists** → evaluate each probe's intent against the snapshot
   ("Mode: files + snapshot (taken <time from SNAPSHOT.md>)"):
   - task objects: `.lab-snapshot/tasks/<nn-slug>/ns-<ns>.yaml` (namespace labels included), `ns-<ns>.missing` = namespace absent;
     Secrets only as names/types/key names in `ns-<ns>.secrets.txt`
   - cluster-wide: `cluster.yaml` (admission policies, RuntimeClasses), `cluster-rbac.yaml` (non-default ClusterRoles/Bindings)
   - node files: `nodes/<node>/<absolute path>` (kube-apiserver manifest, kubelet configs, files from `.meta/snapshot.conf`)
   - Derive what a probe would have returned (e.g. `auth can-i` from the Role/RoleBinding YAML). If the snapshot can't decide
     an item (runtime behaviour, a file that wasn't captured), mark it **unclear**, never fail.
   - If files in `work/` are newer than the snapshot, say so: the live state may not include the learner's latest work.
   - If an item fails in `.lab-snapshot/` but passes in `.lab-snapshot.prev/` (the lab run before), the live work was most
     likely lost in a lab restart: mark it **unclear** (not fail) and tell the learner to re-apply `work/` and `/grade` again.
3. **Neither** → files only ("Mode: files only").

## Single task

1. Read `TASK.md`, then `.meta/rubric.md`.
2. Inspect everything under `work/` (manifests, `commands.sh`, saved copies of node files).
3. Execute the rubric's live probes one by one, or evaluate them against the snapshot (see evidence sources).
   - A probe that finds no object, while the matching file in `work/` is correct, usually means the lab was
     rebuilt since the learner applied it. Mark the item **unclear**, and tell them to re-apply `work/` and `/grade` again.
4. Mark each item **pass** / **fail** / **unclear** with evidence (file and line, or probe output).
5. Result: **PASS** (all must-pass items), **PARTIAL** (some), **FAIL** (none or almost none). Points as in the rubric.

## Whole session / mock exam

Delegate: start one **cks-grader** subagent per task, **in parallel** (one message, several Agent calls).
Give each the task path and the evidence source (lab running, or the snapshot path and time, or files only). Then merge their verdicts, compute the total out of 100
(pass at 67), fill the scoring sheet and the domain breakdown in `sessions/<id>/SESSION.md`, and report.
Never put solutions into `SESSION.md`.

## Output (per task)

```markdown
## Grade: <nn-slug> — PASS | PARTIAL | FAIL (<earned>/<possible> pts)
**Mode:** files + live lab | files + snapshot (taken <time>) | files only

### Must-pass
- [x] … (evidence)
- [ ] … (what is missing, not how to fix it)

### Nice-to-have
- …

### Exam efficiency
- faster approach in one line; namespace or API-version nits

### Next
- retry, `/hint`, or `/explain-solution`
```

## Feedback rules

- Point at the failed requirement, not at the fixed YAML. One direction tip is fine
  ("compare the policy's podSelector with the frontend's labels").
- Flag removed or deprecated APIs and wrong namespaces.
- Credit correct items briefly.

## Update progress

Create or update `state/progress.md` (start from `state/progress.example.md`). Record:
- date, session/task, domain, result and points
- failing domains under **Weak domains**
- the task theme under **Avoid repeats**
- a line under **Notes for next generate**

Nothing in it may leave the machine: it is gitignored and stays local.
