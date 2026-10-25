export EDITOR=nvim
export VISUAL=nvim

# Compatibility variables used by existing personal scripts.
export MS_ZSH_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
export MS_LOCAL="$HOME/.local"
export MS_SL="$MS_LOCAL/_suckless"
export MS_SL_REPO="$MS_SL/repo"

# Keep package-manager command paths, but leave runtime versions to mise.
for _ms_bin in /opt/podman/bin /snap/bin; do
  [[ -d $_ms_bin ]] && path+=("$_ms_bin")
done
unset _ms_bin

# Optional man-page formatting; ordinary man remains available without bat.
if (( $+commands[bat] )); then
  export MANPAGER="sh -c 'col -bx | bat --language man --style plain --paging always --pager \"less -RFX\"'"
  export MANROFFOPT=-c
elif (( $+commands[batcat] )); then
  export MANPAGER="sh -c 'col -bx | batcat --language man --style plain --paging always --pager \"less -RFX\"'"
  export MANROFFOPT=-c
fi
