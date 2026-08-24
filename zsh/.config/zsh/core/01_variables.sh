# -------------------------------------------------
#   ZSH | variables
#   - load choosing plugins
# -------------------------------------------------
function ms_zsh_variables() {

  #-- Fix Locale --#
  export LANGUAGE="en_US.UTF-8"
  export LANG="en_US.UTF-8"
  export LC_ALL="en_US.UTF-8"

  #-- Preferred editor for local and remote sessions --#
  export EDITOR='nvim'
  export SHELL="/bin/zsh"
  export TERM='xterm-256color'
  if command -v bat >/dev/null 2>&1; then
    export MANPAGER="sh -c 'col -bx | bat --language man --style plain --paging always --squeeze-blank --pager \"less -RFX\"'"
    export MANROFFOPT="-c"
  elif command -v batcat >/dev/null 2>&1; then
    export MANPAGER="sh -c 'col -bx | batcat --language man --style plain --paging always --squeeze-blank --pager \"less -RFX\"'"
    export MANROFFOPT="-c"
  fi

  #-- History in cache directory --#
  export HISTFILE=~/.cache/zsh/history
  export HISTSIZE=10000000
  export SAVEHIST=$HISTSIZE

  #-- MS Variables --#
  export MS_LOCAL="$HOME/.local"
  export MS_SL="$MS_LOCAL/_suckless"
  export MS_SL_REPO="$MS_SL/repo"
  export MS_GIT_REPOS="$HOME/msdata/git/"

  #-- docker-tools Variables --#
  # TODO: adapt DOCKER_TOOLS app to new OCI naming convention
  export DOCKER_TOOLS_VOLUMES_BKP="$HOME/_docker/_volumes/"

  #-- Load custom Variables --#
  [ -f "$MS_ZSH_CONFIG/custom/01_variables.zsh" ] && source "$MS_ZSH_CONFIG/custom/01_variables.zsh"

}
