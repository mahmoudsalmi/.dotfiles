#!/usr/bin/env bash
# Usage: notify.sh "<title>" "<message>" [low|default|high] [url]
set -euo pipefail
title="${1:?title required}"; msg="${2:?message required}"
prio="${3:-default}"; url="${4:-}"
sent=0

if command -v terminal-notifier >/dev/null 2>&1; then
  args=(-title "$title" -message "$msg" -group "sd-$$")
  [[ "$prio" == high ]] && args+=(-sound default)
  [[ -n "$url" ]] && args+=(-open "$url")
  terminal-notifier "${args[@]}" >/dev/null 2>&1 && sent=1
fi

if [[ -n "${SD_NTFY_TOPIC:-}" ]]; then
  server="${SD_NTFY_SERVER:-https://ntfy.sh}"
  case "$prio" in high) p=4;; low) p=2;; *) p=3;; esac
  hdrs=(-H "Title: $title" -H "Priority: $p")
  [[ -n "$url" ]] && hdrs+=(-H "Click: $url")
  [[ -n "${SD_NTFY_TOKEN:-}" ]] && hdrs+=(-H "Authorization: Bearer $SD_NTFY_TOKEN")
  curl -fsS "${hdrs[@]}" -d "$msg" "$server/$SD_NTFY_TOPIC" >/dev/null && sent=1
fi

if [[ $sent -eq 0 ]]; then
  echo "sd-notify: no channel available (install terminal-notifier or set SD_NTFY_TOPIC)" >&2
  exit 2
fi
