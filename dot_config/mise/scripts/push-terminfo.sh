#!/usr/bin/env bash
# Push a local terminfo entry to a remote user or system database over SSH.
set -euo pipefail

host=${usage_host:-}
entry=${usage_entry:-xterm-ghostty}
system=${usage_system:-false}

if [[ -z $host || $host == -* || $host == *[[:space:]]* ]]; then
  printf 'Invalid or missing SSH host: %s\n' "$host" >&2
  exit 2
fi
if [[ ! $entry =~ ^[[:alnum:]][[:alnum:]_.+-]*$ ]]; then
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

if [[ $system == true ]]; then
  # Stage the entry separately so SSH keeps its terminal for sudo's password
  # prompt instead of consuming the terminfo data from standard input.
  printf 'Installing %s system-wide on %s (sudo may prompt)...\n' "$entry" "$host"
  ssh -T "$host" 'infocmp -D | grep -Fx /etc/terminfo >/dev/null' || {
    printf 'Remote /etc/terminfo is not a terminfo search directory on %s\n' "$host" >&2
    exit 1
  }
  remote_tmp=$(ssh -T "$host" 'mktemp -d /tmp/chezmoi-terminfo.XXXXXXXXXX')
  if [[ ! $remote_tmp =~ ^/tmp/chezmoi-terminfo\.[[:alnum:]]{10}$ ]]; then
    printf 'Unexpected remote temporary directory: %s\n' "$remote_tmp" >&2
    exit 1
  fi
  cleanup() {
    ssh -T "$host" "rm -rf -- '$remote_tmp'" ||
      printf 'Warning: could not remove remote directory %s on %s\n' "$remote_tmp" "$host" >&2
  }
  trap cleanup EXIT
  infocmp -x "$entry" | ssh -T "$host" "cat > '$remote_tmp/entry'"

  # Check the compiled file in the system database itself, not a user entry.
  first=${entry:0:1}
  printf -v first_hex '%x' "'$first"
  ssh -tt "$host" "sudo tic -x -o /etc/terminfo '$remote_tmp/entry' && \
    { test -f '/etc/terminfo/$first/$entry' || test -f '/etc/terminfo/$first_hex/$entry'; } && \
    infocmp -A /etc/terminfo '$entry' >/dev/null" || {
    printf 'System-wide installation or verification failed for %s on %s\n' "$entry" "$host" >&2
    exit 1
  }
else
  printf 'Installing %s terminfo for %s...\n' "$entry" "$host"
  infocmp -x "$entry" |
    ssh -T "$host" 'mkdir -p "$HOME/.terminfo" && tic -x -'
  ssh -T "$host" "infocmp '$entry' >/dev/null" || {
    printf 'Remote terminfo verification failed for %s on %s\n' "$entry" "$host" >&2
    exit 1
  }
fi
printf 'Verified %s terminfo on %s.\n' "$entry" "$host"
