# Node shells of the CKS lab: point at the exam shell when a lab tool is typed on a node.
command_not_found_handle() {
  case "$1" in
    trivy|kubesec|kube-linter|cosign|bom|helm|kind)
      printf "%s: not installed on the nodes. It's in the exam shell; type exit to return there.\n" "$1" >&2 ;;
    *)
      printf 'bash: %s: command not found\n' "$1" >&2 ;;
  esac
  return 127
}
PS1='\[\e[1;33m\]\h\[\e[0m\]:\w# '
