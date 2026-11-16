#!/bin/bash
# Seed for task {{NN}}-{{SLUG}}. Runs inside the cks-toolbox container via `./cks seed`.
# The working directory is this task folder; $CKS_TASK_DIR holds its absolute path.
#
# Contract:
#   - IDEMPOTENT: it runs again after every fresh cluster (each ./cks start, ./cks reset).
#   - Lab only: kubectl talks to the lab; `ssh <node> '<cmd>'` runs a command on a node.
#   - No secrets, no downloads from unknown hosts, no published ports, no hostNetwork.
#   - Images: small, pinned, open source (registry.k8s.io, official Docker Hub images). Never Bitnami.
#   - Print symptoms at most, never the fix.
set -euo pipefail

NS={{NAMESPACE}}

kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -n "$NS" -f - <<'YAML'
# baseline objects (insecure / broken on purpose)
YAML

# Node-level state (example): only change it if it isn't there yet.
# ssh cks-control-plane 'grep -q -- "--profiling=true" /etc/kubernetes/manifests/kube-apiserver.yaml || \
#   sed -i "s/- kube-apiserver$/- kube-apiserver\n    - --profiling=true/" /etc/kubernetes/manifests/kube-apiserver.yaml'

echo "seeded: {{NN}}-{{SLUG}}"
