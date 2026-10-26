#!/usr/bin/env bash
# The exam's `ssh <node>`: shell or command on a lab node, pinned to the lab podman machine.
# Usage: cluster/node.sh [control-plane|worker|worker2] [command...]
#   cluster/node.sh                                          # interactive shell on the control plane
#   cluster/node.sh worker2 cat /var/lib/kubelet/config.yaml
#   cluster/node.sh worker sh -c 'cat > /var/lib/kubelet/seccomp/profiles/audit.json' < audit.json
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

NODE="${1:-control-plane}"
case "${NODE}" in
  control-plane | worker | worker2) ;;
  *)
    echo "usage: cluster/node.sh [control-plane|worker|worker2] [command...]" >&2
    exit 2
    ;;
esac
[[ $# -gt 0 ]] && shift

need podman
CONTAINER="${CLUSTER_NAME}-${NODE}"

if [[ $# -eq 0 ]]; then
  exec podman exec -it "${CONTAINER}" bash
fi
FLAGS=(-i)
[[ -t 0 && -t 1 ]] && FLAGS=(-it)
exec podman exec "${FLAGS[@]}" "${CONTAINER}" "$@"
