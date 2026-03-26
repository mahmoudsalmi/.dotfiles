# -------------------------------------------------
#   ZSH | startup | prompt
#   - load prompt
# -------------------------------------------------
function ms_zsh_startup_prompt {
  #if command -v fastfetch >/dev/null; then
  #  fastfetch
  #fi

  # if command -v pfetch >/dev/null; then
  #   pfetch --stat
  # fi

  znap eval starship "starship init zsh"
  znap prompt
}

# -------------------------------------------------
#   ZSH | startup | load some dev tools
#   - load luarocks
#   - load rust
#   - load fnm
#   - load angular
#   - load pnpm
#   - load sdkman
# -------------------------------------------------
function __ms_zsh_startup_dev_tools() {
  # ---------------------------------------------------------- jj
  # Disabled: jj completion is slow (~120ms), uncomment if needed
  # if command -v jj >/dev/null; then
  #   znap fpath _jj 'jj util completion zsh'
  # fi

  # ---------------------------------------------------------- pass [password-store]
  [ -f $HOME/.password-store/init-pass.zsh ] && source $HOME/.password-store/init-pass.zsh

  # ---------------------------------------------------------- Lua [PATH Luarocks]
  [ -d $HOME/.luarocks/bin ] && export PATH=$HOME/.luarocks/bin:$PATH

  # ---------------------------------------------------------- Rust [PATH cargo]
  [ -d $HOME/.cargo/bin ] && export PATH=$HOME/.cargo/bin:$PATH
  if command -v rustup >/dev/null; then
    znap fpath _rustup 'rustup  completions zsh'
    znap fpath _cargo 'rustup  completions zsh cargo'
  fi

  # ---------------------------------------------------------- Nodejs [FNM]
  if [ -d $HOME/.fnm ]; then
    export PATH=$HOME/.fnm:$PATH
  elif [ -d $HOME/.local/share/fnm ]; then
    export PATH="$HOME/.local/share/fnm:$PATH"
  fi

  if command -v fnm >/dev/null; then
    # Use znap eval to cache fnm env output (much faster)
    znap eval fnm-init 'fnm env --use-on-cd'
    znap fpath _fnm 'fnm completions'
  fi

  # ---------------------------------------------------------- Nodejs [PNPM]
  export PNPM_HOME=$HOME/.local/share/pnpm
  mkdir -p $PNPM_HOME
  export PATH=$PNPM_HOME:$PATH

  # Disabled: pnpm completion is slow (~288ms), uncomment if needed
  # if command -v pnpm >/dev/null; then
  #   znap fpath _pnpm 'pnpm completion zsh'
  # fi

  # ---------------------------------------------------------- Nodejs [angular]
  # Disabled: ng completion is very slow (~800ms), uncomment if needed
  # if command -v ng >/dev/null; then
  #   znap fpath _ng 'ng completion script'
  # fi

  # ---------------------------------------------------------- java/sdk [SDKMAN]
  export SDKMAN_DIR="$HOME/.sdkman"
  
  # Set up Java, Gradle, Kotlin paths directly (fast, bypasses security scanners)
  if [[ -d "$SDKMAN_DIR/candidates/java/current" ]]; then
    export JAVA_HOME="$SDKMAN_DIR/candidates/java/current"
    export PATH="$JAVA_HOME/bin:$PATH"
  fi
  
  if [[ -d "$SDKMAN_DIR/candidates/gradle/current" ]]; then
    export PATH="$SDKMAN_DIR/candidates/gradle/current/bin:$PATH"
  fi
  
  if [[ -d "$SDKMAN_DIR/candidates/kotlin/current" ]]; then
    export PATH="$SDKMAN_DIR/candidates/kotlin/current/bin:$PATH"
  fi
  
  if [[ -d "$SDKMAN_DIR/candidates/maven/current" ]]; then
    export PATH="$SDKMAN_DIR/candidates/maven/current/bin:$PATH"
  fi
  
  # Lazy-load SDKMAN only when 'sdk' command is used
  sdk() {
    unset -f sdk
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
    sdk "$@"
  }

  # ---------------------------------------------------------- OBRSTACK [PATH]
  if [[ -d "$HOME/.orbstack" ]]; then
    znap fpath orbctl 'orbctl completion zsh'

    if [[ -f "$HOME/.orbstack/ssh/config" && ! -f "$HOME/.ssh/config.d/orbstack" ]]; then
      mkdir -p $HOME/.ssh/config.d
      ln -s "$HOME/.orbstack/ssh/config" "$HOME/.ssh/config.d/orbstack"
    fi
  fi

  # ---------------------------------------------------------- Go [PATH]
  [ -d $HOME/go/bin ] && export PATH=$HOME/go/bin:$PATH
}

# -------------------------------------------------
#   ZSH | startup | update $PATH
#   - load dev tools
#   - load Rancher Desktop
#   - load snap
#   - load local bin
# -------------------------------------------------
function __ms_zsh_startup_path() {
  __ms_zsh_startup_dev_tools

  # ---------------------------------------------------------- Docker [Rancher Desktop]
  # TODO !Deprecated
  [ -d $HOME/.rd/bin ] && export PATH=$HOME/.rd/bin:$PATH

  # ---------------------------------------------------------- Snap [PATH]
  [ -d /snap/bin ] && export PATH=/snap/bin:$PATH

  # ---------------------------------------------------------- local bin [PATH]
  [ -d $HOME/.local/bin ] && export PATH=$HOME/.local/bin:$PATH
}

# -------------------------------------------------
#   ZSH | startup | prompt
#   - load prompt
# -------------------------------------------------
function ms_zsh_startup_load {
  __ms_zsh_startup_path

  #-- custom --#
  [ -f "$MS_ZSH_CONFIG/custom/07_startup.zsh" ] && source "$MS_ZSH_CONFIG/custom/07_startup.zsh"
}
