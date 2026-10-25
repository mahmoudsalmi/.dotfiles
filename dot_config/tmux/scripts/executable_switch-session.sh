#!/bin/sh
# Session labels are for display; IDs are used as exact tmux targets.
set -eu
command -v fzf >/dev/null 2>&1 || { printf 'fzf is not on PATH\n' >&2; exit 1; }
tab=$(printf '\t')
sessions=$(tmux list-sessions -F "#{session_id}${tab}#{session_name} (#{session_windows} windows)") || exit 1
selected=$(printf '%s\n' "$sessions" |
    fzf --reverse --header='Switch Session' --delimiter="$tab" --with-nth=2.. \
        --preview='tmux capture-pane -t {1} -p') || exit 0
[ -n "$selected" ] || exit 0
target=${selected%%"$tab"*}
tmux switch-client -t "$target"

