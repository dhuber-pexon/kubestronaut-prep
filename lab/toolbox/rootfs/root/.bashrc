# Exam-style shell for the CKS lab (runs inside the cks-toolbox container).
[ -z "${PS1:-}" ] && return

[ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion

# Same shortcuts most people set up in the first minute of the real exam.
alias k=kubectl
complete -o default -F __start_kubectl k
export do="--dry-run=client -o yaml"
export now="--force --grace-period 0"

# A stray Ctrl-D must not end the session: leaving this shell tears the lab down.
export IGNOREEOF=10

PS1='\[\e[1;36m\]cks\[\e[0m\]:\w\$ '

if [ -n "${CKS_ROOT:-}" ] && [ -d "$CKS_ROOT" ] && [ "$PWD" = "$HOME" ]; then
  cd "$CKS_ROOT" || true
fi

if [ -z "${CKS_BANNER_SHOWN:-}" ]; then
  export CKS_BANNER_SHOWN=1
  cat <<'BANNER'
CKS lab shell  -  kubectl (alias k), trivy, kubesec, kube-linter, cosign, bom, helm
  ssh cks-control-plane | ssh cks-worker   node shell, like the exam (sudo -i works)
  k get nodes                              cluster "cks", Kubernetes v1.37
  exit                                     leave (you are asked before the lab is destroyed)
BANNER
fi
