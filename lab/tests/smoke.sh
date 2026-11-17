#!/bin/bash
# ./cks smoke: functional check of the running lab (the scriptable part of Part A in post-podman-steps.md).
# Runs INSIDE the cks-toolbox container (kubectl, the ssh shim and podman-remote are available).
#
# Side effects: creates the namespaces cks-smoke, cks-smoke-psa and cks-smoke-vap and the cluster-scoped
# ValidatingAdmissionPolicy cks-smoke-registries, and removes all of them again. Nodes are only read
# (plus one image pull on cks-worker). Checks that change nodes (encryption at rest, audit logging,
# seccomp Localhost, kubelet config, anonymous auth) stay manual: they restart kube-apiserver or kubelet.
set -u
ROOT="${CKS_ROOT:?CKS_ROOT is not set}"
TBIMG="${CKS_TOOLBOX_IMAGE:?CKS_TOOLBOX_IMAGE is not set}"
FIX="$ROOT/lab/tests/pod-insecure.yaml"
NS=cks-smoke
PASS=0
FAIL=0

ok()  { PASS=$((PASS + 1)); printf 'PASS  %-24s %s\n' "$1" "${2:-}"; }
bad() { FAIL=$((FAIL + 1)); printf 'FAIL  %-24s %s\n' "$1" "${2:-}"; }
cleanup() {
  kubectl delete ns "$NS" cks-smoke-psa cks-smoke-vap --ignore-not-found --wait=false >/dev/null 2>&1
  kubectl delete validatingadmissionpolicybinding cks-smoke-registries --ignore-not-found >/dev/null 2>&1
  kubectl delete validatingadmissionpolicy cks-smoke-registries --ignore-not-found >/dev/null 2>&1
}
# Tools run in a throwaway copy of the toolbox WITHOUT network: proves they work offline.
offline() { podman run --rm --network none --security-opt label=disable -v "$ROOT:$ROOT:ro" -w /tmp "$TBIMG" "$@"; }

# ---------------------------------------------------------------------------------- cluster
r="$(kubectl get --raw /readyz 2>&1)"
if [ "$r" = ok ]; then ok api-ready; else bad api-ready "$r"; echo "smoke: API not ready, stopping."; exit 1; fi
n="$(kubectl get nodes --no-headers 2>/dev/null | awk '$2 == "Ready"' | wc -l)"
if [ "$n" -eq 2 ]; then ok nodes-ready "2/2"; else bad nodes-ready "$n/2 Ready"; fi

# Leftovers of an aborted run must be gone before the namespaces are created again.
kubectl delete ns "$NS" cks-smoke-psa cks-smoke-vap --ignore-not-found --timeout=120s >/dev/null 2>&1
cleanup
trap cleanup EXIT

# ---------------------------------------------------------------------------------- workloads
kubectl create ns "$NS" >/dev/null
kubectl -n "$NS" apply -f - >/dev/null <<'YAML'
apiVersion: v1
kind: Pod
metadata: {name: web, labels: {app: web}}
spec:
  containers: [{name: web, image: "nginx:1.29-alpine"}]
---
apiVersion: v1
kind: Pod
metadata: {name: client, labels: {app: client}}
spec:
  containers: [{name: c, image: "busybox:1.37", command: [sleep, "3600"]}]
---
apiVersion: v1
kind: Pod
metadata: {name: hardened}
spec:
  securityContext: {seccompProfile: {type: RuntimeDefault}}
  containers:
  - name: c
    image: "busybox:1.37"
    command: [sleep, "3600"]
    securityContext: {readOnlyRootFilesystem: true, allowPrivilegeEscalation: false}
YAML
if kubectl -n "$NS" wait --for=condition=Ready pod/web pod/client pod/hardened --timeout=180s >/dev/null 2>&1; then
  ok workloads "3 pods Ready"
  ip="$(kubectl -n "$NS" get pod web -o jsonpath='{.status.podIP}')"
  before="$(kubectl -n "$NS" exec client -- wget -qO- -T 3 "http://$ip" 2>/dev/null | grep -c 'Welcome to nginx')"
  kubectl -n "$NS" apply -f - >/dev/null <<'YAML'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: default-deny-ingress}
spec: {podSelector: {}, policyTypes: [Ingress]}
YAML
  sleep 5
  if kubectl -n "$NS" exec client -- wget -qO- -T 3 "http://$ip" >/dev/null 2>&1; then after=reachable; else after=blocked; fi
  if [ "${before:-0}" -ge 1 ] && [ "$after" = blocked ]; then ok networkpolicy "reachable before, blocked after deny-all"
  else bad networkpolicy "before=${before:-0} after=$after"; fi

  out="$(kubectl -n "$NS" exec hardened -- touch /x 2>&1)"
  case "$out" in *"Read-only file system"*) ok readonly-rootfs ;; *) bad readonly-rootfs "$out" ;; esac

  sc="$(kubectl -n "$NS" exec hardened -- grep '^Seccomp:' /proc/1/status 2>&1 | tr -s ' \t' ' ')"
  if [ "$sc" = "Seccomp: 2" ]; then ok seccomp-runtimedefault "filter active in the container"; else bad seccomp-runtimedefault "$sc"; fi

  # Snapshot of live state (lab/snapshot.sh) on a throwaway session in /tmp. A Secret with a known value
  # must never be captured, and key material must be refused even when a task lists it.
  kubectl -n "$NS" create secret generic smoke-secret --from-literal=password=smoke-secret-value >/dev/null
  ss=/tmp/cks-smoke-session
  rm -rf "$ss"
  mkdir -p "$ss/tasks/01-smoke/.meta"
  echo "# smoke" > "$ss/tasks/01-smoke/TASK.md"
  printf 'namespaces=%s\nnode_files=cks-control-plane:/etc/kubernetes/pki/ca.key\n' "$NS" > "$ss/tasks/01-smoke/.meta/snapshot.conf"
  bash "$ROOT/lab/snapshot.sh" "$ss" smoke >/dev/null 2>&1
  snap="$ss/.lab-snapshot"
  b64="$(printf smoke-secret-value | base64)"
  if [ -f "$snap/tasks/01-smoke/ns-$NS.yaml" ] && grep -q 'name: web' "$snap/tasks/01-smoke/ns-$NS.yaml" \
     && grep -q 'smoke-secret type=Opaque keys=password' "$snap/tasks/01-smoke/ns-$NS.secrets.txt" \
     && [ -s "$snap/nodes/cks-control-plane/etc/kubernetes/manifests/kube-apiserver.yaml" ] \
     && ! grep -rqF -e smoke-secret-value -e "$b64" "$snap" \
     && [ ! -e "$snap/nodes/cks-control-plane/etc/kubernetes/pki/ca.key" ]; then
    ok snapshot "objects + node files saved; Secret value and key material excluded"
  else
    bad snapshot "unexpected content in $snap"
  fi
  rm -rf "$ss"
else
  bad workloads "pods not Ready within 180 s"
fi

# ---------------------------------------------------------------------------------- access control
a="$(kubectl auth can-i list secrets --as system:serviceaccount:default:default 2>&1)"
if [ "$a" = no ]; then ok rbac "default SA cannot list secrets"; else bad rbac "$a"; fi

kubectl create ns cks-smoke-psa >/dev/null
kubectl label ns cks-smoke-psa pod-security.kubernetes.io/enforce=restricted >/dev/null
out="$(kubectl -n cks-smoke-psa run x --image=nginx:1.29-alpine --dry-run=server 2>&1)"
case "$out" in *"violates PodSecurity"*) ok pod-security "restricted rejects a non-compliant pod" ;; *) bad pod-security "$out" ;; esac

kubectl create ns cks-smoke-vap >/dev/null
kubectl label ns cks-smoke-vap cks-smoke-vap=on >/dev/null
kubectl apply -f - >/dev/null <<'YAML'
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata: {name: cks-smoke-registries}
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - {apiGroups: [""], apiVersions: [v1], operations: [CREATE, UPDATE], resources: [pods]}
  validations:
  - expression: "object.spec.containers.all(c, c.image.startsWith('registry.k8s.io/'))"
    message: "only registry.k8s.io images are allowed"
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata: {name: cks-smoke-registries}
spec:
  policyName: cks-smoke-registries
  validationActions: [Deny]
  matchResources: {namespaceSelector: {matchLabels: {cks-smoke-vap: "on"}}}
YAML
denied=no
i=0
while [ "$i" -lt 15 ]; do   # the policy needs a few seconds to become active
  out="$(kubectl -n cks-smoke-vap run bad --image=nginx:1.29-alpine --dry-run=server 2>&1)"
  case "$out" in *"only registry.k8s.io images are allowed"*) denied=yes; break ;; esac
  i=$((i + 1)); sleep 2
done
allowed="$(kubectl -n cks-smoke-vap run good --image=registry.k8s.io/pause:3.10 --dry-run=server 2>&1)"
case "$denied:$allowed" in
  yes:*created*) ok admission-policy "denies docker.io, admits registry.k8s.io" ;;
  *) bad admission-policy "denied=$denied allowed=$allowed" ;;
esac

# ---------------------------------------------------------------------------------- nodes (read only)
# kube-bench prints a summary per section and then the total; keep the total (last PASS/FAIL pair).
kb="$(ssh cks-control-plane 'kube-bench run --targets master 2>/dev/null' | grep -E '^[0-9]+ checks (PASS|FAIL)' | tail -2 | tr '\n' ' ')"
if [ -n "$kb" ]; then ok kube-bench "$kb"; else bad kube-bench "no summary"; fi

eh="$(ssh cks-control-plane 'etcdctl --endpoints https://127.0.0.1:2379 --cacert /etc/kubernetes/pki/etcd/ca.crt --cert /etc/kubernetes/pki/etcd/server.crt --key /etc/kubernetes/pki/etcd/server.key endpoint health 2>&1')"
case "$eh" in *"is healthy"*) ok etcdctl "endpoint healthy" ;; *) bad etcdctl "$eh" ;; esac

cp="$(ssh cks-worker 'containerd config dump 2>/dev/null | grep -c "config_path = .*/etc/containerd/certs.d"')"
pull="$(ssh cks-worker 'crictl pull docker.io/library/busybox:1.37 2>&1 | tail -1')"
case "$pull" in
  *"Image is up to date"*) if [ "${cp:-0}" -ge 1 ]; then ok registry-mirror "docker.io via mirror.gcr.io"; else bad registry-mirror "config_path missing"; fi ;;
  *) bad registry-mirror "$pull" ;;
esac

ver="$(kubectl get node cks-worker -o jsonpath='{.status.nodeInfo.kubeletVersion}')"
arch="$(kubectl get node cks-worker -o jsonpath='{.status.nodeInfo.architecture}')"
have="$(ssh cks-worker 'sha256sum /usr/bin/kubelet' | cut -d' ' -f1)"
want="$(curl -fsSL --max-time 30 "https://dl.k8s.io/release/$ver/bin/linux/$arch/kubelet.sha256" 2>/dev/null)"
if [ -n "$have" ] && [ "$have" = "$want" ]; then ok binary-checksum "kubelet $ver matches dl.k8s.io"
else bad binary-checksum "node=${have:0:12} published=${want:0:12}"; fi

# ---------------------------------------------------------------------------------- supply chain tools
ks="$(offline kubesec scan "$FIX" 2>&1)"
case "$ks" in
  *'"valid": true'*'"score": -'*) ok kubesec-offline "valid scan, negative score, no network" ;;
  *) bad kubesec-offline "$(printf '%s' "$ks" | grep -m1 '"message"')" ;;
esac

kl="$(offline kube-linter lint "$FIX" 2>&1)"
case "$kl" in *"lint errors"*) ok kube-linter-offline "$(printf '%s' "$kl" | tail -1)" ;; *) bad kube-linter-offline "$(printf '%s' "$kl" | tail -1)" ;; esac

cs="$(offline sh -c 'cd /tmp && echo artifact > f && COSIGN_PASSWORD= cosign generate-key-pair >/dev/null 2>&1 \
  && COSIGN_PASSWORD= cosign sign-blob --key cosign.key --bundle b.json --yes f >/dev/null 2>&1 && echo signed
  cosign verify-blob --key cosign.pub --bundle b.json --insecure-ignore-tlog=true f >/dev/null 2>&1 && echo verified
  echo tampered > f
  cosign verify-blob --key cosign.pub --bundle b.json --insecure-ignore-tlog=true f >/dev/null 2>&1 || echo tamper-rejected
  cosign sign-blob --bundle k.json --yes f >/dev/null 2>&1 || echo keyless-refused' 2>&1 | tr '\n' ' ')"
if [ "$cs" = "signed verified tamper-rejected keyless-refused " ]; then ok cosign-offline "sign, verify, tamper rejected, keyless refused"
else bad cosign-offline "$cs"; fi

tv="$(timeout 300 trivy image --quiet --scanners vuln --severity CRITICAL nginx:1.25 2>&1 | grep -m1 -oE 'Total: [0-9]+ \(CRITICAL: [0-9]+\)')"
if [ -n "$tv" ]; then ok trivy "nginx:1.25 $tv"; else bad trivy "no result"; fi

bm="$(timeout 180 bom generate --image registry.k8s.io/pause:3.10 --format tag-value -o /tmp/smoke.spdx >/dev/null 2>&1 && grep -c '^PackageName:' /tmp/smoke.spdx)"
rm -f /tmp/smoke.spdx
if [ "${bm:-0}" -ge 1 ] 2>/dev/null; then ok sbom "$bm packages (SPDX)"; else bad sbom "no SPDX document"; fi

echo "smoke: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
