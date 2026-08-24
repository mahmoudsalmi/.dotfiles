# -------------------------------------------------
#   ZSH | keybindings
#   - vi-mode bindings, navigation fixes, and custom widgets
#     (sudo toggle, run-help, fzf pickers, zoxide jump, ...)
#
#   SUMMARY (all keys set by ms_zsh_keybinding, in effective order):
#   ----------------------------------------------------------------
#   Mode              Key(s)          Action
#   ----------------------------------------------------------------
#   global            bindkey -v      vi keymap (insert=viins, normal=vicmd)
#   global            (cursor)        beam in insert mode, block in normal mode
#   global            Ctrl-a          beginning-of-line
#   global            Ctrl-e          end-of-line
#   global            Alt-Backspace   backward-kill-word
#   global            Ctrl-Right      forward-word
#   global            Ctrl-Left       backward-word
#   global            Alt-Right       forward-word   (iTerm/tmux escape)
#   global            Alt-Left        backward-word  (iTerm/tmux escape)
#   global            Ctrl-v          edit-command-line (open buffer in $EDITOR)
#   global            Ctrl-x Ctrl-e   edit-command-line (readline-standard alt binding)
#   global            Ctrl-x h        run-help on current command
#   global            Ctrl-x s        toggle "sudo " prefix on current/last command
#   global            Ctrl-f          fzfp (fuzzy search files in $PWD)
#   global            Ctrl-g          open fzfp result in nvim
#   global            Ctrl-t          fzf: insert selected file path  [needs fzf]
#   global            Ctrl-x c        fzf: cd into selected directory [needs fzf]
#   global            Ctrl-x z        zoxide: interactive jump (`zi`) [needs zoxide]
#   ----------------------------------------------------------------
#   NOTE: Alt/Option + letter (e.g. old Alt-s/Alt-h/Alt-c/Alt-z) is
#   intentionally NOT used for custom widgets: macOS Terminal.app/iTerm2
#   intercept it for dead-key/accented-character input by default, so
#   those bindings silently typed garbage instead of firing. Ctrl-x is
#   used as the prefix instead since it's a real control byte that
#   works the same in every terminal without extra configuration.
#   Custom, machine/user-specific bindings can be added in
#   custom/04_keybindings.zsh (sourced at the end of this file) without
#   touching this file.
# -------------------------------------------------

# -------------------------------------------------
#   ZSH | keybinding | vi-mode cursor
#   - block cursor in normal mode, beam in insert
#   - WHY: `bindkey -v` makes zsh behave like vim, but by default the
#     terminal cursor never changes shape, so it's easy to lose track of
#     which mode (insert vs normal) you're in.
#   - HOW: zle calls the `zle-keymap-select` widget every time $KEYMAP
#     changes (vicmd <-> viins), and `zle-line-init` every time a new
#     prompt line starts (always begins in insert). We just print the
#     matching DECSCUSR escape sequence (\e[1 q = block, \e[5 q = beam).
#   - REPRODUCE:
#       1. Open a new terminal, cursor should be a beam (insert mode).
#       2. Press <Esc> -> cursor becomes a solid block (normal mode).
#       3. Press `i` -> cursor becomes a beam again (insert mode).
#     If nothing changes, your terminal emulator may not support
#     DECSCUSR (rare on modern terminals) or is inside a multiplexer
#     that swallows it (see `set -g allow-passthrough` for tmux).
# -------------------------------------------------
function __ms_zsh_vi_cursor() {
  function zle-keymap-select() {
    case $KEYMAP in
      vicmd) print -n '\e[1 q' ;;      # block cursor
      viins|main) print -n '\e[5 q' ;; # beam cursor
    esac
  }
  function zle-line-init() { print -n '\e[5 q' } # beam on new prompt/insert
  zle -N zle-keymap-select
  zle -N zle-line-init
}

# -------------------------------------------------
#   ZSH | keybinding | sudo toggle
#   - prepend/remove "sudo " on current/last command
#   - WHY: classic oh-my-zsh `sudo` plugin behavior, reimplemented here
#     with no external plugin so it works the same in vi insert/normal.
#   - HOW: a custom zle widget inspects $BUFFER (current command line).
#     If empty, it first pulls up the last history entry (`up-history`)
#     so you can "forgot sudo"-fix the command you just typed/ran.
#     Then it toggles the "sudo " prefix on/off.
#   - REPRODUCE:
#       1. Type `apt update` (don't press enter).
#       2. Press Ctrl-x then s -> line becomes `sudo apt update`.
#       3. Press Ctrl-x then s again -> back to `apt update`.
#       4. Press enter to run `apt update` (will fail, permission denied).
#       5. Press Ctrl-x then s on the empty prompt -> recalls
#          `apt update` and prefixes it with sudo in one shot.
# -------------------------------------------------
function __ms_zsh_sudo_widget() {
  function sudo-command-line() {
    [[ -z $BUFFER ]] && zle up-history
    if [[ $BUFFER == sudo\ * ]]; then
      LBUFFER="${LBUFFER#sudo }"
    else
      LBUFFER="sudo $LBUFFER"
    fi
  }
  zle -N sudo-command-line
}

function ms_zsh_keybinding() {
  #-- vi mode --#
  bindkey -v
  export KEYTIMEOUT=1

  #-- vi-mode cursor shape indicator --#
  __ms_zsh_vi_cursor

  #-- Common CTRL bindings --#
  bindkey "^a" beginning-of-line
  bindkey "^e" end-of-line

  #-- Fixes for alt-backspace and arrows keys --#
  bindkey '^[^?' backward-kill-word
  bindkey "^[[1;5C" forward-word    # ctrl-right
  bindkey "^[[1;5D" backward-word   # ctrl-left
  #   ADDED: alt-left/right were missing, only ctrl-left/right existed.
  #   iTerm2/tmux/most terminals send "^[[1;3C"/"^[[1;3D" for Alt+Arrow.
  #   REPRODUCE: type a few words, press Alt-Left repeatedly -> cursor
  #   jumps back one word at a time (same as Ctrl-Left already did).
  bindkey "^[[1;3C" forward-word    # alt-right (iTerm/tmux)
  bindkey "^[[1;3D" backward-word   # alt-left  (iTerm/tmux)

  #-- Edit line in vim with ctrl-v (and standard ctrl-x ctrl-e) --#
  #   ADDED: ^x^e is the traditional readline/zsh binding for
  #   "edit-command-line" (used in bash too), kept alongside the
  #   existing ^v so muscle memory from other shells still works.
  #   REPRODUCE: type a multi-line-ish command, press Ctrl-x then
  #   Ctrl-e (release ctrl in between is fine) -> $EDITOR (nvim) opens
  #   with the buffer content; save & quit -> edited text replaces the
  #   command line.
  bindkey '^v' edit-command-line
  bindkey '^x^e' edit-command-line

  #-- run-help on current command --#
  #   WHY: `run-help` is zsh's built-in "man page for the command
  #   currently on the line" widget (aliases `man` originally but the
  #   real widget is smarter about zsh builtins/functions). It ships
  #   with zsh but is not autoloaded nor bound by default.
  #   NOTE: bound to `Ctrl-x h` (not Alt-h) because Alt/Option + letter
  #   is intercepted by macOS Terminal.app/iTerm2 by default (dead-key
  #   input, e.g. produces accented chars) unless you explicitly enable
  #   "Option as Meta" in terminal prefs. Ctrl-x is a real control byte
  #   so it works everywhere without any terminal config.
  #   REPRODUCE: type `git rebase` (don't press enter), press Ctrl-x
  #   then h -> opens `git-rebase` man page (or `run-help git` fallback).
  autoload -Uz run-help
  bindkey '^xh' run-help

  #-- sudo toggle (Ctrl-x s), like oh-my-zsh's sudo plugin --#
  #   See __ms_zsh_sudo_widget above for behavior + reproduce steps.
  #   NOTE: same Ctrl-x rationale as run-help above (was Alt-s, moved
  #   off Alt because of macOS Option-key dead-key interception).
  __ms_zsh_sudo_widget
  bindkey '^xs' sudo-command-line

  #-- search/edit in current PWD --#
  bindkey -s '^f' 'fzfp\n'
  bindkey -s '^g' 'vi $(fzfp)\n'

  #-- fzf: insert path (ctrl-t) / cd into dir (ctrl-x c) --#
  #   WHY: fzf is installed on this machine (brew) but its own default
  #   keybindings (normally sourced from `fzf --zsh` / shell/*.zsh in
  #   the fzf install) are NOT wired into this config, so Ctrl-t/Ctrl-x c
  #   didn't exist yet. Rather than sourcing fzf's whole shell script
  #   (which also rebinds Ctrl-r, clashing with atuin), we define just
  #   these two widgets ourselves, reusing `fd` for fast file listing
  #   and the same bat preview already used by the `fzfp` alias.
  #   Guarded by `command -v fzf` so machines without fzf are unaffected.
  #   NOTE: cd-picker is bound to `Ctrl-x c` (not Alt-c) for the same
  #   macOS Option-key-dead-key reason explained above at run-help.
  #   REPRODUCE (Ctrl-t):
  #     1. cd into this repo, press Ctrl-t.
  #     2. fzf opens with a file picker + bat preview pane.
  #     3. Select a file (Enter) -> its relative path is inserted at
  #        the cursor position in the current command line.
  #   REPRODUCE (Ctrl-x c):
  #     1. From $HOME, press Ctrl-x then c.
  #     2. fzf opens with a directory picker.
  #     3. Select a directory (Enter) -> shell `cd`s into it and the
  #        prompt is redrawn (`zle reset-prompt`) to reflect the new PWD.
  if command -v fzf >/dev/null 2>&1; then
    __ms_fzf_insert_path() {
      local selected
      selected=$(fd --hidden --exclude .git 2>/dev/null | fzf --preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || ls -la {}') || return
      LBUFFER+="$selected"
      zle redisplay
    }
    zle -N __ms_fzf_insert_path
    bindkey '^t' __ms_fzf_insert_path

    __ms_fzf_cd() {
      local dir
      dir=$(fd --type d --hidden --exclude .git 2>/dev/null | fzf) || return
      cd "$dir" && zle reset-prompt
    }
    zle -N __ms_fzf_cd
    bindkey '^xc' __ms_fzf_cd
  fi

  #-- zoxide: quick interactive jump (ctrl-x z) --#
  #   WHY: zoxide (loaded in 02_plugins.zsh) provides `z <query>` for
  #   fuzzy-jumping to a frecent directory, and `zi` for an interactive
  #   fzf-style picker. `zi` existed as a command but had no keybinding.
  #   NOTE: bound to `Ctrl-x z` (not Alt-z) for the same macOS
  #   Option-key-dead-key reason explained above at run-help.
  #   REPRODUCE:
  #     1. `cd` into a few different directories first (to build up
  #        zoxide's frecency database).
  #     2. From anywhere, press Ctrl-x then z.
  #     3. An interactive fuzzy list of previously-visited directories
  #        appears (same UI as `zi` typed manually); selecting one cds
  #        into it.
  if command -v zoxide >/dev/null 2>&1; then
    bindkey -s '^xz' 'zi\n'
  fi

  #-- custom keybinding --#
  [ -f "$MS_ZSH_CONFIG/custom/04_keybindings.zsh" ] && source "$MS_ZSH_CONFIG/custom/04_keybindings.zsh"
}
