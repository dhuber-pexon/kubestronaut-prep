#!/usr/bin/env bash
# Create the kubestronaut kind cluster (1 CP + 2 workers) on the podman machine.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
CONFIG="${ROOT}/cluster/kind.yaml"

need podman
need kind
need kubectl

ensure_machine_running

if cluster_exists; then
  if kind get kubeconfig --name "${CLUSTER_NAME}" >"${KUBECONFIG_PATH}" 2>/dev/null \
    && kc --request-timeout=5s get --raw /readyz >/dev/null 2>&1; then
    echo "cluster '${CLUSTER_NAME}' already exists."
    echo "Use: cluster/down.sh --keep-machine && cluster/up.sh   to recreate"
    kc get nodes -o wide
    exit 0
  fi
  # Node containers do not survive a machine stop — the lab is ephemeral, so rebuild.
  echo "cluster '${CLUSTER_NAME}' is stale (nodes not running) — recreating..."
  kind delete cluster --name "${CLUSTER_NAME}" --kubeconfig "${KUBECONFIG_PATH}"
fi

echo "Creating kind cluster '${CLUSTER_NAME}'..."
kind create cluster --config "${CONFIG}" --kubeconfig "${KUBECONFIG_PATH}" --wait 5m

kc wait --for=condition=Ready nodes --all --timeout=300s

echo
echo "Nodes:"
kc get nodes -o wide
echo
echo "Use the lab (your ~/.kube/config is untouched):"
echo "  export KUBECONFIG=${KUBECONFIG_PATH}"
echo "Node shell (exam 'ssh'): cluster/node.sh [control-plane|worker|worker2] (or 'Attach Shell' in VS Code)"
echo "CKS add-ons on demand:   cluster/addons.sh falco|gatekeeper|kube-bench|traefik"
echo
echo "Lab ready. Next: /create-tasks or /exam-session"
echo "Limits: AppArmor, gVisor, host OS hardening → file-grade (see cluster/README.md)"
