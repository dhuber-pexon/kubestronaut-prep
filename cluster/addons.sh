#!/usr/bin/env bash
# Install CKS add-ons into the running lab. Pinned versions, idempotent.
# Helm charts are rendered in a throwaway container — no helm on the Mac.
# Usage: cluster/addons.sh falco|gatekeeper|kube-bench|traefik [...]
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

HELM_IMAGE="docker.io/alpine/helm:3.22.1"
FALCO_CHART_VERSION="9.2.1"
GATEKEEPER_VERSION="v3.23.1"
KUBE_BENCH_VERSION="v0.16.0"
TRAEFIK_CHART_VERSION="42.1.3"
GATEWAY_API_VERSION="v1.6.3"

usage() {
  echo "usage: cluster/addons.sh falco|gatekeeper|kube-bench|traefik [...]" >&2
  exit 2
}

# Render charts for the lab's actual Kubernetes version.
helm_template() {
  local kube_version
  kube_version="$(kc get nodes -o jsonpath='{.items[0].status.nodeInfo.kubeletVersion}')"
  podman run --rm "${HELM_IMAGE}" template "$@" --kube-version "${kube_version}"
}

apply() {
  kc apply --server-side --force-conflicts "$@"
}

ensure_ns() {
  kc create namespace "$1" --dry-run=client -o yaml | kc apply -f - >/dev/null
}

install_falco() {
  ensure_ns falco
  helm_template falco falco --repo https://falcosecurity.github.io/charts \
    --version "${FALCO_CHART_VERSION}" --namespace falco \
    --set driver.kind=modern_ebpf --set tty=true \
    | apply -n falco -f -
  if ! kc -n falco rollout status daemonset/falco --timeout=300s; then
    kc -n falco logs daemonset/falco -c falco --tail=20 || true
    echo "error: Falco did not start — modern eBPF probe likely unsupported on this VM kernel." >&2
    echo "Falco tasks fall back to file-grade (rules files + sample event output)." >&2
    exit 1
  fi
  echo "falco: ready — alerts: kubectl -n falco logs -f daemonset/falco -c falco"
}

install_gatekeeper() {
  apply -f "https://raw.githubusercontent.com/open-policy-agent/gatekeeper/${GATEKEEPER_VERSION}/deploy/gatekeeper.yaml"
  kc -n gatekeeper-system rollout status deployment/gatekeeper-controller-manager --timeout=300s
  kc -n gatekeeper-system rollout status deployment/gatekeeper-audit --timeout=300s
  echo "gatekeeper: ready — create ConstraintTemplates + Constraints (kubectl get constrainttemplates)"
}

install_kube_bench() {
  local target
  ensure_ns kube-bench
  kc -n kube-bench delete job kube-bench-master kube-bench-node --ignore-not-found >/dev/null
  for target in master node; do
    curl -fsSL "https://raw.githubusercontent.com/aquasecurity/kube-bench/${KUBE_BENCH_VERSION}/job-${target}.yaml" \
      | sed "s#aquasec/kube-bench:latest#aquasec/kube-bench:${KUBE_BENCH_VERSION}#" \
      | kc -n kube-bench apply -f -
  done
  kc -n kube-bench wait --for=condition=complete job/kube-bench-master job/kube-bench-node --timeout=300s
  for target in master node; do
    echo "===== kube-bench ${target} ====="
    kc -n kube-bench logs "job/kube-bench-${target}"
  done
  echo "kube-bench: done — rerun with: cluster/addons.sh kube-bench"
}

install_traefik() {
  apply -f "https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/standard-install.yaml"
  ensure_ns traefik
  helm_template traefik traefik --repo https://traefik.github.io/charts \
    --version "${TRAEFIK_CHART_VERSION}" --namespace traefik --skip-crds \
    --set service.type=NodePort --set providers.kubernetesGateway.enabled=true \
    --set providers.kubernetesCRD.enabled=false \
    --set global.checkNewVersion=false --set global.sendAnonymousUsage=false \
    | apply -n traefik -f -
  kc -n traefik rollout status deployment/traefik --timeout=300s
  echo "traefik: ready — default IngressClass 'traefik' + Gateway API; test in-cluster via svc traefik.traefik"
}

[[ $# -ge 1 ]] || usage
for addon in "$@"; do
  case "${addon}" in
    falco | gatekeeper | kube-bench | traefik) ;;
    *) usage ;;
  esac
done

ensure_cluster_up
for addon in "$@"; do
  echo "Installing ${addon}..."
  case "${addon}" in
    falco) install_falco ;;
    gatekeeper) install_gatekeeper ;;
    kube-bench) install_kube_bench ;;
    traefik) install_traefik ;;
  esac
done
