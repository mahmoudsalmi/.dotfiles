#!/usr/bin/env bash
# sd-start-work helper.
#   start-work.sh ignore  [<worktree>]                 ensure .work/ and .temp/ are git-ignored (local exclude)
#   start-work.sh create  <branch> <key> <brief-dir>   create worktree via wto, copy brief -> .work/<key>/, print path
#   start-work.sh open    <worktree> <key> [<cmd>]     open a tmux window (if in tmux), optionally run <cmd>
set -euo pipefail

die() { echo "start-work: $*" >&2; exit 1; }

ensure_ignored() {
  local wt="${1:-$PWD}" exclude
  exclude="$(git -C "$wt" rev-parse --path-format=absolute --git-common-dir)/info/exclude"
  mkdir -p "$(dirname "$exclude")"; touch "$exclude"
  for p in .work/ .temp/; do
    git -C "$wt" check-ignore -q "$p/x" 2>/dev/null || echo "$p" >> "$exclude"
  done
}

cmd="${1:-}"; shift || true
case "$cmd" in
  ignore) ensure_ignored "${1:-$PWD}" ;;

  create)
    branch="${1:?branch}"; key="${2:?key}"; brief="${3:?brief-dir}"
    [[ -f "$brief/brief.md" ]] || die "no brief.md in $brief"
    command -v wto >/dev/null || die "wto not installed"
    git check-ref-format --branch "$branch" >/dev/null || die "invalid branch: $branch"
    git fetch --quiet origin || true
    wto new -y "$branch" >&2
    path="$(wto status --format json | jq -r --arg b "$branch" '.worktrees[] | select(.branch==$b) | .path' | head -1)"
    [[ -n "$path" && -d "$path" ]] || die "cannot resolve worktree path for $branch"
    ensure_ignored "$path"
    mkdir -p "$path/.work/$key" "$path/.temp"
    cp -R "$brief/." "$path/.work/$key/"
    printf -- '- %s · start-work · worktree created for %s\n' "$(date -u +%FT%TZ)" "$branch" >> "$path/.work/$key/LOG.md"
    echo "$path"
    ;;

  open)
    path="${1:?worktree}"; key="${2:?key}"; run="${3:-}"
    if [[ -z "${TMUX:-}" ]]; then
      echo "not in tmux; run: cd '$path'${run:+ && $run}"; exit 0
    fi
    # Reuse the session wto created for this worktree (wto new --tmux), else open a window here.
    win="$(tmux list-panes -a -F '#{session_name}:#{window_index} #{pane_current_path}' \
      | awk -v p="$path" '$2==p {print $1; exit}')"
    [[ -z "$win" ]] && win="$(tmux new-window -d -P -F '#{session_name}:#{window_index}' -n "$key" -c "$path")"
    [[ -n "$run" ]] && tmux send-keys -t "$win" "$run" C-m
    echo "tmux window $win"
    ;;

  *) sed -n '2,6p' "$0"; exit 1 ;;
esac
