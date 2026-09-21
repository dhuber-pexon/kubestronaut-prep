#!/usr/bin/env bash
# Show kubestronaut kind cluster status.
set -euo pipefail

CLUSTER_NAME="kubestronaut"

if ! command -v kind >/dev/null 2>&1; then
  echo "kind: not installed"
  exit 1
fi

if ! kind get clusters 2>/dev/null | grep -qx "${CLUSTER_NAME}"; then
  echo "cluster: ${CLUSTER_NAME} — not found"
  echo "Create with: cluster/up.sh"
  exit 0
fi

echo "cluster: ${CLUSTER_NAME} — present"
if command -v kubectl >/dev/null 2>&1; then
  CTX="kind-${CLUSTER_NAME}"
  if kubectl config get-contexts -o name 2>/dev/null | grep -qx "${CTX}"; then
    echo "context: ${CTX}"
    kubectl --context "${CTX}" get nodes -o wide 2>/dev/null || echo "nodes: unreachable"
    echo
    kubectl --context "${CTX}" get ns 2>/dev/null | head -n 20 || true
  else
    echo "context ${CTX} missing from kubeconfig"
  fi
else
  echo "kubectl: not installed"
fi
