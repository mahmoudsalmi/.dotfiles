# History is persistent state, rather than disposable cache.
_ms_history_dir="${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
if [[ ! -d $_ms_history_dir ]]; then
  (umask 077; mkdir -p -- "$_ms_history_dir")
fi
HISTFILE="$_ms_history_dir/history"
HISTSIZE=100000
SAVEHIST=100000

# Import the previous config's history once; never delete its original file.
if [[ ! -e $HISTFILE && -f $HOME/.cache/zsh/history ]]; then
  (umask 077; cp -- "$HOME/.cache/zsh/history" "$HISTFILE"; chmod 600 -- "$HISTFILE")
fi
unset _ms_history_dir

setopt APPEND_HISTORY EXTENDED_HISTORY SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST HIST_FIND_NO_DUPS HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_SAVE_NO_DUPS HIST_VERIFY
