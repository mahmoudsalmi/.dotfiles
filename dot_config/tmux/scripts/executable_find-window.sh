#!/bin/sh
# Keep session and window IDs separate from human-readable labels.
set -eu
command -v fzf >/dev/null 2>&1 || { printf 'fzf is not on PATH\n' >&2; exit 1; }
tab=$(printf '\t')
windows=$(tmux list-windows -a -F "#{session_id}${tab}#{window_id}${tab}#{session_name}:#{window_index} — #{window_name}") || exit 1
selected=$(printf '%s\n' "$windows" |
    fzf --reverse --header='Find Window' --delimiter="$tab" --with-nth=3.. \
        --preview='tmux capture-pane -t {2} -p') || exit 0
[ -n "$selected" ] || exit 0
session=${selected%%"$tab"*}
remaining=${selected#*"$tab"}
window=${remaining%%"$tab"*}
tmux select-window -t "$window"
tmux switch-client -t "$session"

