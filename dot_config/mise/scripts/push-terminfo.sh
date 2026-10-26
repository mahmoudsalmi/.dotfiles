#!/usr/bin/env bash
# Push a local terminfo entry to a remote user's ~/.terminfo over SSH.
set -euo pipefail

host=${usage_host:-}
entry=${usage_entry:-xterm-ghostty}

if [[ -z $host || $host == -* || $host == *[[:space:]]* ]]; then
  printf 'Invalid or missing SSH host: %s\n' "$host" >&2
  exit 2
fi
if [[ ! $entry =~ ^[[:alnum:]_.+-]+$ ]]; then
  printf 'Invalid terminfo entry name: %s\n' "$entry" >&2
  exit 2
fi

for command_name in infocmp ssh; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$command_name" >&2
    exit 1
  fi
done

if ! infocmp -x "$entry" >/dev/null 2>&1; then
  printf 'Local terminfo entry not found: %s\n' "$entry" >&2
  exit 1
fi

printf 'Installing %s terminfo for %s...\n' "$entry" "$host"
infocmp -x "$entry" |
  ssh -T "$host" 'mkdir -p "$HOME/.terminfo" && tic -x -'
ssh -T "$host" "infocmp '$entry' >/dev/null" || {
  printf 'Remote terminfo verification failed for %s on %s\n' "$entry" "$host" >&2
  exit 1
}
printf 'Verified %s terminfo on %s.\n' "$entry" "$host"
