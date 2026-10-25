# Executables belong to mise; initialization belongs to interactive Zsh.
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
  ms-zoxide-jump() {
    zi
    zle reset-prompt
    return 0
  }
  zle -N ms-zoxide-jump
  bindkey -M viins '^xz' ms-zoxide-jump
  bindkey -M vicmd '^xz' ms-zoxide-jump
fi

# Retain Up-arrow and vi history navigation; Atuin owns Ctrl-R.
if (( $+commands[atuin] )); then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi
