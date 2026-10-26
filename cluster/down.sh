#!/usr/bin/env bash
# Destroy the kubestronaut kind cluster and stop the podman machine.
# Usage: cluster/down.sh [--keep-machine]
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

KEEP_MACHINE=false
for arg in "$@"; do
  case "${arg}" in
    --keep-machine) KEEP_MACHINE=true ;;
    *)
      echo "usage: cluster/down.sh [--keep-machine]" >&2
      exit 2
      ;;
  esac
done

# Fast no-op when nothing is running (the SessionEnd hook calls this every time).
if ! command -v podman >/dev/null 2>&1 || [[ "$(machine_state)" != "running" ]]; then
  rm -f "${KUBECONFIG_PATH}"
  echo "podman machine '${MACHINE}' not running — nothing to delete"
  exit 0
fi

if command -v kind >/dev/null 2>&1 && cluster_exists; then
  echo "Deleting kind cluster '${CLUSTER_NAME}'..."
  kind delete cluster --name "${CLUSTER_NAME}" --kubeconfig "${KUBECONFIG_PATH}"
else
  echo "cluster '${CLUSTER_NAME}' not found"
fi
rm -f "${KUBECONFIG_PATH}"

if [[ "${KEEP_MACHINE}" == false ]]; then
  echo "Stopping podman machine '${MACHINE}'..."
  podman machine stop "${MACHINE}"
fi
echo "Done."
