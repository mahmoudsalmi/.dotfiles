# Register after compinit. Generate/load completion code only on first Tab.
# No downloads and no fzf --zsh/keybinding scripts are sourced here.
autoload -Uz _gnu_generic
zmodload zsh/stat

typeset -gA _MS_TOOL_COMPLETION_STAMP _MS_TOOL_COMPLETION_HANDLER

_ms_generate_completion() {
  case $1 in
    mise) command mise completion zsh ;;
    chezmoi) command chezmoi completion zsh ;;
    rg) command rg --generate complete-zsh ;;
    fd) command fd --gen-completions zsh ;;
    bat) command bat --completion zsh ;;
    starship) command starship completions zsh ;;
    atuin) command atuin gen-completions --shell zsh ;;
    gh) command gh completion --shell zsh ;;
    *) return 1 ;;
  esac
}

_ms_complete_tool() {
  local tool=${service:-${words[1]}}
  local executable=${commands[$tool]:-}
  [[ -n $executable ]] || { _files; return; }
  executable=${executable:A}
  # A shim is a link to mise itself: identify the selected tool behind it.
  if (( $+commands[mise] )) && [[ $tool != mise && $executable == ${commands[mise]:A} ]]; then
    executable=$(command mise which "$tool" 2>/dev/null) || { _files; return; }
    executable=${executable:A}
  fi
  local -A bin_stat
  zstat -H bin_stat -- "$executable" 2>/dev/null || { _gnu_generic "$@"; return; }
  local stamp="$executable:$bin_stat[mtime]:$bin_stat[size]"
  local handler=${_MS_TOOL_COMPLETION_HANDLER[$tool]:-}

  if [[ ${_MS_TOOL_COMPLETION_STAMP[$tool]:-} != $stamp || -z $handler ]]; then
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/tool-completions"
    local cache="$cache_dir/_$tool" stamp_file="$cache_dir/$tool.origin"
    local loaded=no generated=no tmp root candidate
    local -a candidates
    # A cache belongs to the exact installed binary, not merely its short name.
    if [[ -r $cache && -r $stamp_file && $(<"$stamp_file") == $stamp ]]; then
      loaded=yes
    else
      if (umask 077; mkdir -p -- "$cache_dir"); then
        tmp=$(mktemp "$cache_dir/$tool.XXXXXXXX") || return 1
        if _ms_generate_completion "$tool" > "$tmp" 2>/dev/null &&
            [[ -s $tmp ]] && command zsh -n "$tmp" 2>/dev/null; then
          generated=yes
        elif (( $+commands[mise] )); then
          # Some release archives ship completion files instead of a generator.
          # Limit discovery to this tool's install directory, on first use only.
          local install_tool=$tool
          [[ $tool == ya ]] && install_tool=yazi
          root=$(command mise where "$install_tool" 2>/dev/null) || root=''
          if [[ -n $root && -d $root ]]; then
            candidates=("$root"/**/_${tool}(N.) "$root"/**/${tool}.zsh(N.))
            for candidate in "${candidates[@]}"; do
              # Never accidentally load an integration script (notably fzf's).
              if command grep -q '^#compdef' "$candidate" && command zsh -n "$candidate" 2>/dev/null; then
                command cp -- "$candidate" "$tmp"
                generated=yes
                break
              fi
            done
          fi
        fi
        if [[ $generated == yes ]]; then
          command mv -f -- "$tmp" "$cache"
          print -r -- "$stamp" > "$stamp_file"
          loaded=yes
        else
          command rm -f -- "$tmp"
        fi
      fi
    fi
    handler=_gnu_generic
    if [[ $loaded == yes ]]; then
      # #compdef files may be bare function bodies or self-defining scripts.
      # Autoload supports both; sourcing them does not.
      fpath=("$cache_dir" $fpath)
      unfunction "_$tool" 2>/dev/null || true
      autoload -Uz "_$tool"
      handler=_${tool}
    fi
    _MS_TOOL_COMPLETION_STAMP[$tool]=$stamp
    _MS_TOOL_COMPLETION_HANDLER[$tool]=$handler
    # Retain the dispatcher to notice a mise version change during this shell.
    compdef _ms_complete_tool "$tool"
  fi
  "$handler" "$@"
}

for _ms_tool in mise chezmoi rg fd fzf bat lsd starship atuin zoxide gh btop fastfetch lazygit yazi ya; do
  if (( $+commands[$_ms_tool] )); then
    compdef _ms_complete_tool "$_ms_tool"
  fi
done
unset _ms_tool
