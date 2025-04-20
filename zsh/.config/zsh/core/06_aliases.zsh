# -------------------------------------------------
#   ZSH | alias | alias
#   - define aliases
# -------------------------------------------------
function __ms_zsh_alias() {

  if command -v lsd >/dev/null 2>&1; then
    alias ls='lsd --group-directories-first'     # simple ls
    alias la='lsd -al --group-directories-first' # all files and dirs
    alias ll='lsd -l --group-directories-first'  # long format
    alias lt='lsd -lt --group-directories-first' # ordered by date
    alias l='lsd -alt --group-directories-first' # my preferred alias
  elif command -v eza >/dev/null 2>&1; then
    alias ls='eza --color=always --group-directories-first'                  # simple ls
    alias la='eza -al --color=always --group --group-directories-first'      # all files and dirs
    alias ll='eza -l --color=always --group --group-directories-first'       # long format
    alias lt='eza -l -snew --color=always --group --group-directories-first' # ordered by date
    alias l='eza -al -snew --color=always --group --group-directories-first' # my preferred alias
  elif command -v exa >/dev/null 2>&1; then
    alias ls='exa --color=always --group-directories-first'                  # simple ls
    alias la='exa -al --color=always --group --group-directories-first'      # all files and dirs
    alias ll='exa -l --color=always --group --group-directories-first'       # long format
    alias lt='exa -l -snew --color=always --group --group-directories-first' # ordered by date
    alias l='exa -al -snew --color=always --group --group-directories-first' # my preferred alias
  else
    # alias ls='ls ' not needed
    alias la='ls -al --color=always' # all files and dirs
    alias ll='ls -l --color=always'  # long format
    alias lt='ls -lt --color=always' # ordered by date
    alias l='ls -alt --color=always' # my preferred alias
  fi

  alias fzfp="fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'"

  alias vi=nvim
  alias vim=nvim

  alias :q=exit
}

# -------------------------------------------------
#   ZSH | alias | functions
#   - define utils functions
# -------------------------------------------------
function __ms_zsh_functions() {

  function batdiff() {
    git diff --name-only --relative --diff-filter=d | xargs bat --diff
  }

  function t() {
    tail -f "$@" | bat --paging=never -l log
  }

  {
    typeset -fx batdiff
    typeset -fx t
  } >/dev/null 2>&1
}

# -------------------------------------------------
#   ZSH | alias
#   - define aliases and utils functions
# -------------------------------------------------
function ms_zsh_alias() {
  __ms_zsh_alias
  __ms_zsh_functions
  [ -f "$MS_ZSH_CONFIG/custom/06_aliases.zsh" ] && source "$MS_ZSH_CONFIG/custom/06_aliases.zsh"
}
