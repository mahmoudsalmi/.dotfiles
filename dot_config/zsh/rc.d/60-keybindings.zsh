# Vi editing with familiar movement keys in both insert and normal mode.
bindkey -v
KEYTIMEOUT=10  # hundredths of a second; tolerate SSH escape-sequence latency

autoload -Uz edit-command-line run-help add-zle-hook-widget
zle -N edit-command-line

ms-sudo-command-line() {
  [[ -z $BUFFER ]] && zle up-history
  [[ -z $BUFFER ]] && return 0
  if [[ $BUFFER == 'sudo '* ]]; then
    BUFFER=${BUFFER#sudo }
    (( CURSOR = CURSOR > 5 ? CURSOR - 5 : 0 ))
  else
    BUFFER="sudo $BUFFER"
    (( CURSOR += 5 ))
  fi
  return 0
}
zle -N ms-sudo-command-line

# Hook registration composes with other widgets instead of replacing them.
ms-vi-cursor() {
  [[ -t 1 && $TERM != dumb ]] || return 0
  case ${KEYMAP:-viins} in
    vicmd) printf '\033[2 q' ;;
    *) printf '\033[6 q' ;;
  esac
}
ms-vi-cursor-reset() {
  [[ -t 1 && $TERM != dumb ]] && printf '\033[0 q'
  return 0
}
add-zle-hook-widget line-init ms-vi-cursor
add-zle-hook-widget keymap-select ms-vi-cursor
add-zle-hook-widget line-finish ms-vi-cursor-reset

# read0/print0 preserves spaces, quotes, and embedded newlines. No eval.
# Callers use synchronous command substitution: asynchronous process
# substitution can suspend a picker when it tries to read /dev/tty.
ms-pick-path() {
  local kind=${1:-f}
  local -a picker_options
  command -v fd >/dev/null 2>&1 && command -v fzf >/dev/null 2>&1 || {
    return 1
  }
  if [[ $kind == f ]] && command -v bat >/dev/null 2>&1; then
    picker_options+=(--preview 'bat --color=always --style=numbers --line-range=:500 -- {}')
  fi
  fd --type "$kind" --hidden --exclude .git --print0 . |
    fzf --read0 --print0 --no-multi --height=70% --layout=reverse --border "${picker_options[@]}"
}

# Standalone file picker retained for use from commands or scripts.
fzfp() {
  local selected
  selected=$(ms-pick-path f) || return 1
  selected=${selected%$'\0'}
  print -r -- "$selected"
}

ms-fzf-insert-path() {
  local selected
  selected=$(ms-pick-path f) || return 0
  selected=${selected%$'\0'}
  LBUFFER+="${(q)selected} "
  zle redisplay
}
ms-fzf-edit-file() {
  local selected
  command -v nvim >/dev/null 2>&1 || { zle -M 'Install neovim with mise first'; return 0; }
  selected=$(ms-pick-path f) || return 0
  selected=${selected%$'\0'}
  nvim -- "$selected"
  zle reset-prompt
}
ms-fzf-cd() {
  local selected
  selected=$(ms-pick-path d) || return 0
  selected=${selected%$'\0'}
  builtin cd -- "$selected" && zle reset-prompt
  return 0
}
ms-edit-local-zsh() {
  local file="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/local.zsh"
  if (( ! $+commands[nvim] )); then
    zle -M 'Neovim is not available'
    return 0
  fi
  command nvim -- "$file"
  zle reset-prompt
}
zle -N ms-fzf-insert-path
zle -N ms-fzf-edit-file
zle -N ms-fzf-cd
zle -N ms-edit-local-zsh

# Bind both vi maps explicitly; preserve vi's ordinary letter commands.
for _ms_keymap in viins vicmd; do
  bindkey -M "$_ms_keymap" '^a' beginning-of-line
  bindkey -M "$_ms_keymap" '^e' end-of-line
  bindkey -M "$_ms_keymap" '^[^?' backward-kill-word
  bindkey -M "$_ms_keymap" '^[[1;5C' forward-word
  bindkey -M "$_ms_keymap" '^[[1;5D' backward-word
  bindkey -M "$_ms_keymap" '^[[1;3C' forward-word
  bindkey -M "$_ms_keymap" '^[[1;3D' backward-word
  bindkey -M "$_ms_keymap" '^v' edit-command-line
  bindkey -M "$_ms_keymap" '^x^e' edit-command-line
  bindkey -M "$_ms_keymap" '^xh' run-help
  bindkey -M "$_ms_keymap" '^xs' ms-sudo-command-line
  bindkey -M "$_ms_keymap" '^f' ms-fzf-insert-path
  bindkey -M "$_ms_keymap" '^t' ms-fzf-insert-path
  bindkey -M "$_ms_keymap" '^g' ms-fzf-edit-file
  bindkey -M "$_ms_keymap" '^xc' ms-fzf-cd
  bindkey -M "$_ms_keymap" '^x^z' ms-edit-local-zsh
  bindkey -M "$_ms_keymap" '^r' history-incremental-search-backward
done
unset _ms_keymap
