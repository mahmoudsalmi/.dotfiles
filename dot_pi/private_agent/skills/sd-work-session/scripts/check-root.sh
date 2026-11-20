#!/bin/sh
# Read-only preflight. On success stdout is just the configured root.
set -eu
if [ -z "${SD_WORK_DIR:-}" ]; then
    printf '%s\n' 'SD_WORK_DIR is not set. Please choose an existing directory outside your repositories.' >&2
    if command -v mise >/dev/null 2>&1; then
        printf '%s\n' 'Set it in the parent directory’s mise.toml (or ~/.config/mise/config.local.toml for a global default):' '[env]' 'SD_WORK_DIR = "/absolute/path/to/work-area"' 'From a child repository, restart Pi with: mise exec -- pi' >&2
    else
        printf '%s\n' 'In the shell that will launch Pi, run:' 'export SD_WORK_DIR="/absolute/path/to/work-area"' 'Then start Pi from that shell.' >&2
    fi
    exit 1
fi
case "$SD_WORK_DIR" in
    /*) ;;
    *) printf '%s\n' 'Please set SD_WORK_DIR to an absolute path and restart Pi.' >&2; exit 1 ;;
esac
if [ ! -d "$SD_WORK_DIR" ] || [ ! -x "$SD_WORK_DIR" ]; then
    printf '%s\n' 'SD_WORK_DIR is not an accessible directory. Please create the intended root or correct the variable before retrying.' >&2
    exit 1
fi
printf '%s\n' "$SD_WORK_DIR"
