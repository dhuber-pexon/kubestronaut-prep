#!/usr/bin/env bash
# Destroy the kubestronaut kind cluster.
set -euo pipefail

CLUSTER_NAME="kubestronaut"

if ! command -v kind >/dev/null 2>&1; then
  echo "error: 'kind' not found on PATH" >&2
  exit 1
fi

if ! kind get clusters 2>/dev/null | grep -qx "${CLUSTER_NAME}"; then
  echo "cluster '${CLUSTER_NAME}' not found — nothing to delete"
  exit 0
fi

echo "Deleting kind cluster '${CLUSTER_NAME}'..."
kind delete cluster --name "${CLUSTER_NAME}"
echo "Done."
