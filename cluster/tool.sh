#!/usr/bin/env bash
# Run CKS CLI tools as throwaway containers in the podman machine — nothing installed on the Mac.
# The repo is mounted read-only at its own path, so relative paths from the repo work.
# Usage: cluster/tool.sh trivy|kubesec [args...]
#   cluster/tool.sh trivy image nginx:1.25
#   cluster/tool.sh trivy k8s --report summary          (needs cluster/up.sh)
#   cluster/tool.sh kubesec scan sessions/<id>/tasks/<nn>-<slug>/work/pod.yaml
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TRIVY_IMAGE="docker.io/aquasec/trivy:0.76.1"
KUBESEC_IMAGE="docker.io/kubesec/kubesec:v2.15.0"

usage() {
  echo "usage: cluster/tool.sh trivy|kubesec [args...]" >&2
  exit 2
}

[[ $# -ge 1 ]] || usage
TOOL="$1"
shift
case "${TOOL}" in
  trivy | kubesec) ;;
  *) usage ;;
esac

need podman
ensure_machine_running

# Keep the caller's working dir when it is inside the repo (the only mounted path).
WORKDIR="${ROOT}"
[[ "${PWD}/" == "${ROOT}/"* ]] && WORKDIR="${PWD}"
RUN=(podman run --rm -i -v "${ROOT}:${ROOT}:ro" -w "${WORKDIR}")

case "${TOOL}" in
  trivy)
    # Host network + lab kubeconfig so `trivy k8s` reaches the kind API server.
    [[ -f "${KUBECONFIG_PATH}" ]] && RUN+=(--network host -e "KUBECONFIG=${KUBECONFIG_PATH}")
    exec "${RUN[@]}" -v kubestronaut-trivy-cache:/root/.cache "${TRIVY_IMAGE}" "$@"
    ;;
  kubesec)
    # Image is amd64-only; on Apple silicon the podman machine emulates it (Rosetta/qemu).
    exec "${RUN[@]}" --platform linux/amd64 "${KUBESEC_IMAGE}" "$@"
    ;;
  *) usage ;;
esac
