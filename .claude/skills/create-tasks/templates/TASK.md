# Task {{NN}}: {{TITLE}}

**Domain:** {{DOMAIN}} · **Difficulty:** {{DIFFICULTY}} · **Flavor:** {{FLAVOR}}
**Weight (mock points):** {{POINTS}} · **Suggested time:** {{TIME}}
**Where:** {{WHERE}}   <!-- e.g. "cluster cks, namespace team-blue" or "node cks-control-plane (ssh cks-control-plane)" -->

## Scenario

{{SCENARIO}}

## Requirements

{{REQUIREMENTS}}

## Given

{{GIVEN}}   <!-- files in ../given/, seeded objects/symptoms, or "nothing" -->

## Deliverables (in this task's `work/`)

{{DELIVERABLES}}

## Rules

- Solve in the exam shell (`./cks` in the VS Code terminal). Node access works as in the exam: `ssh <node>`, then `sudo -i`.
- Put your manifests and commands in this task's `work/`. For changes made on a node, also save a copy of each
  changed file in `work/`, e.g. `ssh cks-control-plane cat /etc/kubernetes/manifests/kube-apiserver.yaml > work/kube-apiserver.yaml`.
  The lab is rebuilt on every start, so `work/` is what survives.
- Do not edit `TASK.md`, `given/` or `.meta/`.
- Docs: https://kubernetes.io/docs/ and the docs of the lab's tools, as in the exam.
