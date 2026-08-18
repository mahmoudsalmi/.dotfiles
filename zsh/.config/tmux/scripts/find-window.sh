#!/bin/sh
# Find and switch to a window across all sessions using fzf
TARGET=$(tmux list-windows -a -F '#{session_name}:#{window_index} — #{window_name}' | \
  fzf --reverse --header='Find Window' | \
  sed 's/ .*//')
[ -n "$TARGET" ] && tmux select-window -t "$TARGET" && tmux switch-client -t "$TARGET"
