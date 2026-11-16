#!/bin/bash
# PreToolUse guard for every Bash call in this project (see .claude/settings.json).
#
# Blocks commands that would
#   - expose anything beyond 127.0.0.1 (published ports, host networking, tunnels, listeners)
#   - install software or change settings on the Mac
#   - upload project content to outside services
#   - bypass ./cks (kubectl & co. are deliberately not installed on the Mac)
# Exit 2 blocks the call; stderr tells Claude why.
#
# This is a speed bump. The hard guarantee is structural (no published ports, API on loopback)
# and is proven by `./cks verify-local`. JSON is decoded with macOS's built-in plutil (no jq).

input="$(cat)"
cmd="$(printf '%s' "$input" | /usr/bin/plutil -extract tool_input.command raw -o - - 2>/dev/null)" || cmd=""
[ -n "$cmd" ] || cmd="$input"   # anything undecodable is checked raw instead of waved through

block() {
  printf 'Blocked by .claude/hooks/guard.sh: %s\n' "$1" >&2
  exit 2
}

flat="$(printf '%s' "$cmd" | tr '\n\t' '  ')"
lower="$(printf '%s' "$flat" | tr '[:upper:]' '[:lower:]')"
W='(^|[^[:alnum:]_.-])'      # word start
E='([^[:alnum:]_-]|$)'        # word end
has()  { printf '%s' "$lower" | grep -Eq -- "$1"; }
hasc() { printf '%s' "$flat"  | grep -Eq -- "$1"; }   # case-sensitive

LOCAL_ONLY="this project is local-only; nothing may be reachable beyond 127.0.0.1."
NO_INSTALL="nothing is installed or changed on the Mac; every tool runs inside the lab via ./cks."

# --- tunnels and public exposure ---------------------------------------------------------
if has "${W}(ngrok|cloudflared|localtunnel|zrok|pinggy|serveo|localhost\.run|tunnelmole|cloud-provider-kind)${E}" \
   || has "${W}lt[[:space:]]+(--port|-p)${E}" \
   || has "${W}tailscale[[:space:]]+(funnel|serve)${E}" \
   || has "${W}bore[[:space:]]+(local|server)${E}" \
   || hasc "(^|[[:space:];&|])ssh([[:space:]][^;&|]*)?[[:space:]]-[A-Za-z]*[Rg]"; then
  block "tunnels and remote port forwards are not allowed: $LOCAL_ONLY"
fi

# --- listeners on all interfaces ----------------------------------------------------------
if has "(http\.server|simplehttpserver)" && ! has "(--bind|-b)[[:space:]=]+(127\.0\.0\.1|localhost)"; then
  block "an HTTP server would listen on all interfaces: $LOCAL_ONLY"
fi
if has "${W}(nc|ncat|netcat)([[:space:]][^;&|]*)?[[:space:]]-[a-z]*l" || has "socat[^;&|]*tcp[46]?-listen"; then
  block "opening a listening socket is not allowed: $LOCAL_ONLY"
fi
if has "(--address|--bind|--bind-address|--host|--listen|--listen-address|--addr)[[:space:]=]+(0\.0\.0\.0|\[?::\]?|\*)${E}"; then
  block "binding to all interfaces is not allowed: $LOCAL_ONLY"
fi

# --- installs and system changes on the Mac ----------------------------------------------
if has "${W}brew[[:space:]]+(install|reinstall|upgrade|tap|bundle|link|services)${E}" \
   || has "${W}(pip|pip3|pipx|gem|cargo|go|port|mas)[[:space:]]+install${E}" \
   || has "${W}uv[[:space:]]+(tool|pip)[[:space:]]+install${E}" \
   || has "${W}(npm|pnpm)[[:space:]]+(i|install|add)[[:space:]][^;&|]*(-g|--global)${E}" \
   || has "${W}yarn[[:space:]]+global${E}" \
   || has "(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z|da|k|fi)?sh${E}" \
   || has "${W}(softwareupdate|launchctl|networksetup|pfctl|systemsetup|tmutil|csrutil|spctl)${E}" \
   || has "${W}installer[[:space:]]+-pkg${E}" \
   || has "${W}defaults[[:space:]]+write${E}"; then
  block "$NO_INSTALL"
fi
if has "(>|tee)[^;&|]*(~|\\\$home|/users/[^/[:space:]]+)/\.(zshrc|zprofile|zshenv|bashrc|bash_profile|profile|kube|docker|ssh|gitconfig|config/containers)"; then
  block "writing to files outside the project folder is not allowed."
fi

# --- uploads to outside services -----------------------------------------------------------
if has "${W}gh[[:space:]]+gist${E}" || has "(pastebin|0x0\.st|transfer\.sh|termbin|file\.io|paste\.rs|ix\.io|hastebin|dpaste)"; then
  block "uploading project content to outside services is not allowed."
fi
if hasc "(^|[[:space:];&|])curl[[:space:]][^;&|]*[[:space:]](-T|--upload-file|-F|--form|--data|--data-binary|--data-raw|--data-urlencode|-d|--json)([[:space:]=]|$)" \
   || hasc "(^|[[:space:];&|])curl[[:space:]][^;&|]*-X[[:space:]]*(POST|PUT|PATCH)" \
   || hasc "(^|[[:space:];&|])wget[[:space:]][^;&|]*--(post-file|post-data|body-file|body-data|method)"; then
  block "uploading data with curl/wget is not allowed in this project."
fi

# --- Podman: only through ./cks; never touch other machines or prune globally --------------
if has "${W}podman[[:space:]]+(machine[[:space:]]+(rm|reset|init|set|os)|system[[:space:]]+(reset|prune|migrate|renumber)|(image|volume|network|container|pod|system)[[:space:]]+prune)${E}"; then
  block "manage the lab VM only through ./cks (./cks down, ./cks purge); never prune or reset Podman globally."
fi

# --- per-command checks (split on ; & |) ----------------------------------------------------
# Quote-aware split: separators inside quotes (e.g. sh -c 'a && b' run inside a container) are not
# command boundaries on the Mac. Quote characters are dropped, quoted ; & | and spaces become "_".
nz="$(printf '%s' "$flat" | awk -v q="'" '{
  s = $0; out = ""; st = 0
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (st == 0) {
      if (c == q) { st = 1; continue }
      if (c == "\"") { st = 2; continue }
      out = out c
    } else if ((st == 1 && c == q) || (st == 2 && c == "\"")) {
      st = 0
    } else {
      out = out ((c ~ /[|;& ]/) ? "_" : c)   # a quoted string stays one word
    }
  }
  print out
}')"
segments="$(printf '%s' "$nz" | tr ';&|' '\n\n\n')"
while IFS= read -r seg; do
  [ -n "$seg" ] || continue
  # strip leading env assignments / `env`
  first="$(printf '%s' "$seg" | sed -E 's/^[[:space:]]*(env[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*//' | awk '{print $1}')"
  case "$first" in
    sudo|doas|su)
      block "$first is not allowed: $NO_INSTALL" ;;
    kubectl|kind|helm|trivy|kubesec|kube-linter|cosign|bom|etcdctl|crictl|k9s|kube-bench|falco)
      block "'$first' is not installed on the Mac on purpose. Use ./cks kubectl …, ./cks node <node> -- …, or the exam shell (./cks)." ;;
  esac
  case "$seg" in
    *podman*|*docker*|*nerdctl*) ;;
    *) continue ;;
  esac
  printf '%s' "$seg" | grep -Eq '(^|[[:space:]])(run|create)([[:space:]]|$)' || continue
  if printf '%s' "$seg" | grep -Eq -- '(^|[[:space:]])(-P|--publish-all)([[:space:]=]|$)'; then
    block "-P/--publish-all would publish ports on all interfaces: $LOCAL_ONLY"
  fi
  if printf '%s' "$seg" | grep -Eq -- '--(network|net)([[:space:]]+|=)host([[:space:]]|$)'; then
    block "host networking is not allowed: $LOCAL_ONLY"
  fi
  pubs="$(printf '%s' "$seg" | grep -oE -- '(^|[[:space:]])(-p|--publish)([[:space:]]+|=)[^[:space:]]+' | sed -E 's/^[[:space:]]*(-p|--publish)([[:space:]]+|=)//' || true)"
  for v in $pubs; do
    case "$v" in
      127.0.0.1:*|localhost:*|'[::1]':*) ;;
      *) block "publishing '$v' would listen on all interfaces. Bind to 127.0.0.1:<port>, or better, don't publish at all (use ./cks)." ;;
    esac
  done
done <<EOF
$segments
EOF

exit 0
