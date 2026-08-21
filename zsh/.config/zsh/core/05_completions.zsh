# -------------------------------------------------
#   ZSH | completions | update fpath
#   - add local fpath
#   - add nix fpath
#   - deduplicate
# -------------------------------------------------
function __update_fpath() {
  #-- add local fpath --#
  fpath=($HOME/.local/share/zsh/site-functions $fpath)

  #-- OpenSpec completions --#
  [ -d "$HOME/.zsh/completions" ] && fpath=("$HOME/.zsh/completions" $fpath)
  
  #-- deduplicate fpath --#
  fpath=(${(u)fpath})
}

# -------------------------------------------------
#   ZSH | completions | load
#   - customize and load zsh completions
# -------------------------------------------------
function __load_completions() {
  _comp_options+=(globdots)		# Include hidden files.

  autoload -Uz compinit

  zstyle ':completion:*' menu select
  zstyle ':completion:*' group-name '' # group results by category
  zstyle ':completion:::::' completer _expand _complete _ignored _approximate # enable approximate matches for completion

  zstyle ':completion:*' completer _expand _complete _ignored _approximate
  zstyle ':completion:*' menu select=2
  zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
  zstyle ':completion:*:descriptions' format '%U%F{yellow}%d%f%u'
  zstyle ':completion:*' rehash true
  zstyle ':completion:*' verbose yes
  zstyle ':completion:*:descriptions' format '%B%d%b'
  zstyle ':completion:*:messages' format '%d'
  zstyle ':completion:*:warnings' format 'No matches for: %d'
  zstyle ':completion:*' group-name ''

  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
  zstyle ':completion:*:default' list-colors "${(s.:.)LS_COLORS}"

  zmodload zsh/complist
  compinit

}

# -------------------------------------------------
#   ZSH | completions
#   - update fpath
#   - load completions
#   - custom completions
# -------------------------------------------------
function ms_zsh_completions() {
  __update_fpath
  __load_completions

  #-- bun completions --#
  [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

  [ -f "$MS_ZSH_CONFIG/custom/05_completions.zsh" ] && source "$MS_ZSH_CONFIG/custom/05_completions.zsh"
}

