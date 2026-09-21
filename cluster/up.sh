#!/usr/bin/env bash
# Create the kubestronaut kind cluster (1 CP + 2 workers).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="kubestronaut"
CONFIG="${ROOT}/cluster/kind.yaml"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: '$1' not found on PATH" >&2
    exit 1
  }
}

need kind
need kubectl
need docker

if ! docker info >/dev/null 2>&1; then
  echo "error: docker daemon not reachable" >&2
  exit 1
fi

if kind get clusters 2>/dev/null | grep -qx "${CLUSTER_NAME}"; then
  echo "cluster '${CLUSTER_NAME}' already exists."
  echo "Use: cluster/down.sh && cluster/up.sh   to recreate"
  kubectl config use-context "kind-${CLUSTER_NAME}" >/dev/null 2>&1 || true
  kubectl get nodes -o wide
  exit 0
fi

echo "Creating kind cluster '${CLUSTER_NAME}'..."
kind create cluster --config "${CONFIG}" --wait 5m

kubectl config use-context "kind-${CLUSTER_NAME}"
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo
echo "Nodes:"
kubectl get nodes -o wide
echo
echo "Lab ready. Next: /create-tasks or /exam-session"
echo "Limits: CKS host harden / AppArmor → file-grade on macOS+kind"
