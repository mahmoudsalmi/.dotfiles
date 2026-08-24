# -------------------------------------------------
#   ZSH | SetOpt
#   - customize zsh options
# -------------------------------------------------
function ms_zsh_setopt() {
  #-- ZSH hooks --#
  # NOTE: also autoloaded by atuin's own init script (core/02_plugins.zsh), kept here
  # explicitly in case atuin is disabled/removed and other hooks are added later.
  autoload -Uz add-zsh-hook

  #-- edit command --#
  autoload edit-command-line
  zle -N edit-command-line

  #-- Enable colors and change prompt --#
  autoload -Uz colors && colors

  #-- set options --#
  setopt always_to_end          # Move cursor to end of word after completion
  setopt append_history         # Dont overwrite history
  setopt auto_list              # Automatically list choices on ambiguous completion
  setopt auto_menu              # Show completion menu on successive tab presses
  setopt auto_pushd             # Automatically push old directory onto the directory stack on `cd`
  setopt autocd                 # Allow changing directories without `cd`
  setopt check_jobs             # Warn about running/suspended jobs before exiting the shell
  setopt complete_in_word       # Allow completion from within a word, not just at the end
  setopt correct                # Suggest command name correction on typos
  setopt extended_glob          # Enable extended globbing patterns (e.g. ^, ~, #)
  setopt extended_history       # Also record time and duration of commands.
  setopt glob_dots              # Include dotfiles in filename globbing without needing a leading dot
  setopt hist_expire_dups_first # Clear duplicates when trimming internal hist.
  setopt hist_find_no_dups      # Dont display duplicates during searches.
  setopt hist_ignore_all_dups   # Remember only one unique copy of the command.
  setopt hist_ignore_dups       # Ignore consecutive duplicates.
  setopt hist_ignore_space      # Ignore commands that start with space.
  setopt hist_reduce_blanks     # Remove superfluous blanks.
  setopt hist_save_no_dups      # Omit older commands in favor of newer ones.
  setopt hist_verify            # Expand history substitution into the command line for review before running it
  setopt interactive_comments   # Allow comments (#) in interactive shell
  setopt long_list_jobs         # Show PID and additional info when listing background jobs
  setopt magic_equal_subst      # Expand `~` and parameters in `foo=~/bar` style assignments
  setopt no_beep                # Disable beep on errors
  setopt no_case_glob           # Case-insensitive filename globbing
  setopt no_hist_beep           # Disable beep on failed history expansion
  setopt no_list_beep           # Disable beep on ambiguous completion listing
  setopt notify                 # Report background job status immediately, not just before next prompt
  setopt numeric_glob_sort      # Sort filenames numerically when globbing (e.g. file2 before file10)
  setopt print_eight_bit        # Print 8-bit characters correctly instead of showing metafied escapes
  setopt print_exit_value       # Print exit value of non-zero-exiting commands
  setopt prompt_subst           # Enable parameter expansion, command substitution in prompts
  setopt pushd_ignore_dups      # Dont push duplicate directories onto the directory stack
  setopt rm_star_wait           # Require confirmation before `rm *` or `rm path/*` executes
  setopt share_history          # Share history between multiple shells
  setopt transient_rprompt      # Remove right-side prompt when accepting a command line

  #-- load and set custom options --#
  [ -f "$MS_ZSH_CONFIG/custom/03_opts.zsh" ] && source "$MS_ZSH_CONFIG/custom/03_opts.zsh"
}
