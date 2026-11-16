#!/bin/bash
# PreToolUse guard for the cks-grader subagent (see .claude/agents/cks-grader.md).
# Grading is read-only: only single ./cks probes that do not change the cluster or the nodes,
# optionally piped into simple text filters. Exit 2 blocks the call.

input="$(cat)"
cmd="$(printf '%s' "$input" | /usr/bin/plutil -extract tool_input.command raw -o - - 2>/dev/null)" || cmd=""
deny() { printf 'cks-grader is read-only: %s\n' "$1" >&2; exit 2; }
[ -n "$cmd" ] || deny "could not read the command."

flat="$(printf '%s' "$cmd" | tr '\n\t' '  ' | sed -E 's#[0-9]?>&[0-9]##g; s#2>/dev/null##g')"

# Quote-aware neutralising: quote characters are dropped, shell metacharacters inside quotes
# become "_", and anything the shell would still expand ($(…), backticks, backslashes,
# unbalanced quotes) becomes a backtick, which is rejected below.
nz="$(printf '%s' "$flat" | awk -v q="'" '{
  s = $0; out = ""; st = 0
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1); n = substr(s, i + 1, 1)
    if (st == 0) {
      if (c == q) { st = 1; continue }
      if (c == "\"") { st = 2; continue }
      if (c == "\\") { out = out "`"; continue }
      out = out c
    } else if (st == 1) {
      if (c == q) { st = 0; continue }
      out = out ((c ~ /[|;&<>]/) ? "_" : c)
    } else {
      if (c == "\"") { st = 0; continue }
      if (c == "`" || c == "\\" || (c == "$" && n == "(")) { out = out "`"; continue }
      out = out ((c ~ /[|;&<>]/) ? "_" : c)
    }
  }
  if (st != 0) out = out "`"
  print out
}')"

case "$nz" in
  *';'*|*'&'*|*'`'*|*'$('*|*'>'*|*'<'*)
    deny "no chaining, background jobs, substitution, escapes or redirection. Run one ./cks probe per call." ;;
esac

first="${nz%%|*}"
rest=""
case "$nz" in *'|'*) rest="${nz#*|}" ;; esac

if ! printf '%s' "$first" | grep -Eq '^[[:space:]]*\./cks[[:space:]]+(kubectl|k|node|status|verify-local)([[:space:]]|$)'; then
  deny "only ./cks kubectl|k|node|status|verify-local are allowed."
fi
# `auth can-i` / `auth whoami` only ask the API ("may X delete Y?") and are allowed, but only directly after
# kubectl; otherwise "kubectl delete pod x auth can-i" would pass as a disguised delete.
if printf '%s' "$first" | grep -Eq '^[[:space:]]*\./cks[[:space:]]+(kubectl|k)[[:space:]]' \
   && ! printf '%s' "$first" | grep -Eq '^[[:space:]]*\./cks[[:space:]]+(kubectl|k)[[:space:]]+auth[[:space:]]+(can-i|whoami)([[:space:]]|$)' \
   && printf '%s' "$first" | grep -Eq '[[:space:]](apply|create|delete|edit|patch|replace|scale|label|annotate|set|drain|cordon|uncordon|taint|rollout|expose|autoscale|debug|cp|run|certificate|proxy|port-forward|attach|reconcile)([[:space:]]|$)'; then
  deny "kubectl verbs that change the cluster are not allowed while grading (use get/describe/auth can-i/exec)."
fi
if printf '%s' "$first" | grep -Eq '^[[:space:]]*\./cks[[:space:]]+node[[:space:]]' \
   && printf '%s' "$first" | grep -Eq '[[:space:]](rm|mv|cp|tee|dd|truncate|chmod|chown|kill|pkill|apt|apt-get|dpkg|useradd|userdel|usermod|systemctl[[:space:]]+(restart|stop|start|disable|enable|mask|daemon-reload)|sed[[:space:]]+-i|crictl[[:space:]]+(rm|rmi|rmp|stop|stopp|run|runp))([[:space:]]|$)'; then
  deny "commands that change a node are not allowed while grading."
fi

if [ -n "$rest" ]; then
  oldifs="$IFS"; IFS='|'; set -f
  for seg in $rest; do
    if ! printf '%s' "$seg" | grep -Eq '^[[:space:]]*(grep|egrep|head|tail|wc|sort|uniq|cut|tr|column|sed[[:space:]]+-n|awk)([[:space:]]|$)'; then
      IFS="$oldifs"; deny "pipes may only feed text filters (grep, head, tail, wc, sort, uniq, cut, tr, column, sed -n, awk)."
    fi
    case "$seg" in *system*|*getline*) IFS="$oldifs"; deny "no system()/getline in filters." ;; esac
  done
  IFS="$oldifs"; set +f
fi
exit 0
