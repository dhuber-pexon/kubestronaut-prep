#!/usr/bin/env bash
# Show kubestronaut lab status: podman machine, kind cluster, nodes, add-ons.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

for tool in podman kind kubectl; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    echo "${tool}: not installed — ${SETUP_HINT}"
    exit 1
  fi
done

STATE="$(machine_state)"
if [[ "${STATE}" == missing ]]; then
  echo "machine: ${MACHINE} — not created — ${SETUP_HINT}"
  exit 0
fi
echo "machine: ${MACHINE} — ${STATE}"
if [[ "${STATE}" != running ]]; then
  echo "cluster: ${CLUSTER_NAME} — down"
  echo "Create with: cluster/up.sh"
  exit 0
fi

if ! cluster_exists; then
  echo "cluster: ${CLUSTER_NAME} — not found"
  echo "Create with: cluster/up.sh"
  exit 0
fi

echo "cluster: ${CLUSTER_NAME} — present"
if [[ ! -f "${KUBECONFIG_PATH}" ]]; then
  echo "kubeconfig ${KUBECONFIG_PATH} missing — rerun cluster/up.sh"
  exit 0
fi
echo "kubeconfig: ${KUBECONFIG_PATH}"
kc get nodes -o wide 2>/dev/null || echo "nodes: unreachable"
echo
kc get ns 2>/dev/null | head -n 20 || true
echo

ADDONS=""
for pair in falco:falco gatekeeper:gatekeeper-system kube-bench:kube-bench traefik:traefik; do
  if kc get ns "${pair#*:}" >/dev/null 2>&1; then
    ADDONS="${ADDONS} ${pair%%:*}"
  fi
done
echo "add-ons:${ADDONS:- none}"
