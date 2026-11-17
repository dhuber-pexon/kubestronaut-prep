#!/bin/bash
# Snapshot of the live lab state of one session, taken by ./cks right before the cluster is destroyed
# (exit, tab close, ./cks down, ./cks reset, session end), so /grade can still grade live work afterwards.
# Runs INSIDE the cks-toolbox container.   Usage: snapshot.sh <absolute session dir> [reason]
#
# Writes <session>/.lab-snapshot/ (built in a temp folder, then swapped in):
#   SNAPSHOT.md                       when, why, API state, notes
#   tasks/<task>/ns-<ns>.yaml         the namespace and its objects (Secrets excluded)
#   tasks/<task>/ns-<ns>.secrets.txt  Secret names, types and key NAMES only, never values
#   cluster.yaml, cluster-rbac.yaml   admission policies, RuntimeClasses, non-default ClusterRoles/Bindings
#   nodes/<node>/<path>               kube-apiserver manifest, kubelet configs, files named in .meta/snapshot.conf
# Never captured: Secret values, anything under */pki/*, *.key, *.pem; `secret:`/`token:`/`password:`
# values in files are redacted. Errors never stop the teardown; they are noted in SNAPSHOT.md.
set -u
S="${1:?usage: snapshot.sh <session dir> [reason]}"
REASON="${2:-teardown}"
[ -d "$S/tasks" ] || { echo "snapshot: no tasks in $S, nothing to do"; exit 0; }
OUT="$S/.lab-snapshot"
TMP="$S/.lab-snapshot.tmp"
rm -rf "$TMP"
mkdir -p "$TMP/tasks" "$TMP/nodes"
NOTES=""
note() { NOTES="$NOTES
- $*"; }
redact() { sed -E 's/^([[:space:]-]*(secret|token|password|client-key-data|client-certificate-data):[[:space:]]*).+$/\1<redacted>/'; }

KINDS=pods,deployments,daemonsets,statefulsets,jobs,cronjobs,services,configmaps,serviceaccounts,roles,rolebindings,networkpolicies,ingresses,resourcequotas,limitranges,persistentvolumeclaims

api=up
[ "$(kubectl get --raw /readyz 2>/dev/null)" = ok ] || { api=down; note "API server not ready: cluster objects could not be captured, only node files."; }

task_namespaces() {   # $1 = task dir: from .meta/snapshot.conf, else the t<NN>-… names in TASK.md
  if [ -f "$1/.meta/snapshot.conf" ] && grep -q '^namespaces=' "$1/.meta/snapshot.conf"; then
    sed -n 's/^namespaces=//p' "$1/.meta/snapshot.conf" | tr ', ' '\n\n'
  else
    grep -ohE '\bt[0-9]{2}-[a-z0-9]([-a-z0-9]*[a-z0-9])?\b' "$1/TASK.md" 2>/dev/null
  fi | grep -v '^$' | sort -u
}

: > "$TMP/.node-files"
for t in "$S"/tasks/*/; do
  t="${t%/}"
  d="$TMP/tasks/$(basename "$t")"
  mkdir -p "$d"
  if [ -f "$t/.meta/snapshot.conf" ]; then
    sed -n 's/^node_files=//p' "$t/.meta/snapshot.conf" | tr ' ,' '\n\n' | grep -v '^$' >> "$TMP/.node-files"
  fi
  [ "$api" = up ] || continue
  for ns in $(task_namespaces "$t"); do
    if ! kubectl get ns "$ns" >/dev/null 2>&1; then
      echo "namespace $ns did not exist at snapshot time" > "$d/ns-$ns.missing"
      continue
    fi
    { kubectl get ns "$ns" -o yaml; echo "---"; kubectl -n "$ns" get "$KINDS" -o yaml 2>/dev/null; } | redact > "$d/ns-$ns.yaml"
    kubectl -n "$ns" get secrets -o go-template='{{range .items}}{{.metadata.name}} type={{.type}} keys={{range $k, $v := .data}}{{$k}} {{end}}{{"\n"}}{{end}}' \
      > "$d/ns-$ns.secrets.txt" 2>/dev/null
  done
done

if [ "$api" = up ]; then
  kubectl get validatingadmissionpolicies,validatingadmissionpolicybindings,runtimeclasses -o yaml 2>/dev/null | redact > "$TMP/cluster.yaml"
  kubectl get clusterroles,clusterrolebindings -l '!kubernetes.io/bootstrapping' -o yaml 2>/dev/null | redact > "$TMP/cluster-rbac.yaml"
  kubectl get nodes -o wide > "$TMP/nodes.txt" 2>&1
fi

DEFAULT_FILES="cks-control-plane:/etc/kubernetes/manifests/kube-apiserver.yaml cks-control-plane:/var/lib/kubelet/config.yaml cks-worker:/var/lib/kubelet/config.yaml"
for nf in $DEFAULT_FILES $(sort -u "$TMP/.node-files"); do
  node="${nf%%:*}"
  path="${nf#*:}"
  case "$node" in cks-control-plane|cks-worker) ;; *) note "skipped $nf (unknown node)"; continue ;; esac
  case "$path" in
    /*/pki/*|*.key|*.pem) note "skipped $nf (key material is never captured)"; continue ;;
    /*) ;;
    *) note "skipped $nf (not an absolute path)"; continue ;;
  esac
  dest="$TMP/nodes/$node$path"
  mkdir -p "$(dirname "$dest")"
  if ssh "$node" "cat '$path'" 2>/dev/null | redact > "$dest" && [ -s "$dest" ]; then :; else
    rm -f "$dest"; note "$nf was not readable"
  fi
done
rm -f "$TMP/.node-files"

{
  echo "# Lab snapshot"
  echo
  echo "- Taken: $(date -u '+%Y-%m-%d %H:%M:%S') UTC, reason: $REASON"
  echo "- API server: $api"
  echo "- Cluster created: $(kubectl get node cks-control-plane -o jsonpath='{.metadata.creationTimestamp}' 2>/dev/null || echo unknown)"
  echo
  echo "Read by /grade and the cks-grader agent when the lab is not running."
  echo "Never captured: Secret values, key material; secret/token/password values in files are redacted."
  if [ -n "$NOTES" ]; then printf '\n## Notes\n%s\n' "$NOTES"; fi
} > "$TMP/SNAPSHOT.md"

rm -rf "$OUT"
mv "$TMP" "$OUT"
echo "snapshot: $(find "$OUT" -type f | wc -l) files in ${OUT#"${CKS_ROOT:-}"/}"
