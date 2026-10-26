#!/usr/bin/env bash
# Shared settings for the kubestronaut lab scripts. Source, do not execute.
# Runtime: kind on a dedicated rootful Podman machine — no Docker required.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="kubestronaut"
MACHINE="kubestronaut"
KUBECONFIG_PATH="${ROOT}/cluster/kubeconfig"
SETUP_HINT="see 'One-time Mac setup' in ${ROOT}/README.md"

# Kubeconfigs and logs written by the scripts are private to the user.
umask 077

# Pin kind and every podman call to the lab machine only.
export KIND_EXPERIMENTAL_PROVIDER=podman
export CONTAINER_CONNECTION="${MACHINE}-root"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: '$1' not found on PATH — ${SETUP_HINT}" >&2
    exit 1
  }
}

# Prints: running | stopped | missing
machine_state() {
  local state
  state="$(podman machine inspect "${MACHINE}" --format '{{.State}}' 2>/dev/null)" || {
    echo "missing"
    return 0
  }
  case "${state}" in
    running) echo "running" ;;
    *) echo "stopped" ;;
  esac
}

# Start the lab machine if needed. Never creates or deletes it (that is the user's job).
ensure_machine_running() {
  local state other
  state="$(machine_state)"
  case "${state}" in
    running) return 0 ;;
    missing)
      echo "error: podman machine '${MACHINE}' does not exist — ${SETUP_HINT}" >&2
      echo "  podman machine init ${MACHINE} --rootful --cpus 4 --memory 8192 --disk-size 50 --volume \"${ROOT}:${ROOT}:ro\"" >&2
      exit 1
      ;;
  esac

  # macOS runs one podman machine at a time.
  other="$(podman machine list --noheading --format '{{.Name}} {{.Running}}' 2>/dev/null \
    | tr -d '*' | awk -v m="${MACHINE}" '$1 != m && $2 == "true" { print $1 }' | head -n 1)"
  if [[ -n "${other}" ]]; then
    echo "error: podman machine '${other}' is running — stop it first: podman machine stop ${other}" >&2
    exit 1
  fi

  echo "Starting podman machine '${MACHINE}'..."
  podman machine start "${MACHINE}"
}

cluster_exists() {
  kind get clusters 2>/dev/null | grep -qx "${CLUSTER_NAME}"
}

kc() {
  kubectl --kubeconfig "${KUBECONFIG_PATH}" "$@"
}

# For scripts that act on a running lab (addons, tools).
ensure_cluster_up() {
  need podman
  need kind
  need kubectl
  if [[ "$(machine_state)" != "running" ]] || ! cluster_exists || [[ ! -f "${KUBECONFIG_PATH}" ]] \
    || ! kc --request-timeout=5s get --raw /readyz >/dev/null 2>&1; then
    echo "error: lab cluster is not running — start it with: cluster/up.sh" >&2
    exit 1
  fi
}
