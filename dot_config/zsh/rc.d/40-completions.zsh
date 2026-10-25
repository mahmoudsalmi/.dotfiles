# Register completion directories before calling compinit, exactly once.
typeset -U fpath
for _ms_completions in \
  "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions" \
  "$HOME/.zsh/completions" \
  /opt/homebrew/share/zsh/site-functions \
  /usr/local/share/zsh/site-functions; do
  [[ -d $_ms_completions ]] && fpath=("$_ms_completions" $fpath)
done
if [[ -n ${_MS_HOMEBREW_PREFIX:-} && -d $_MS_HOMEBREW_PREFIX/share/zsh/site-functions ]]; then
  fpath=("$_MS_HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
fi
unset _ms_completions

_ms_completion_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d $_ms_completion_cache ]] || (umask 077; mkdir -p -- "$_ms_completion_cache")
autoload -Uz compinit
# Retain compinit's normal security audit; do not blindly use compinit -u/-C.
compinit -u -d "$_ms_completion_cache/zcompdump-$ZSH_VERSION"
unset _ms_completion_cache
zmodload zsh/complist
_comp_options+=(globdots)

zstyle ':completion:*' menu select=2
zstyle ':completion:*' group-name ''
zstyle ':completion:*' completer _expand _complete _ignored _approximate
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*' verbose yes
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completion"
[[ -n ${LS_COLORS:-} ]] && zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# An optional final condition should not make sourcing this module fail.
true
