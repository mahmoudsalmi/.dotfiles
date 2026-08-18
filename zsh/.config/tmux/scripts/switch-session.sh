#!/bin/sh
# Switch tmux session using fzf
TARGET=$(tmux list-sessions -F '#{session_name}' | fzf --reverse --header='Switch Session' --preview='tmux capture-pane -t {} -p')
[ -n "$TARGET" ] && tmux switch-client -t "$TARGET"
