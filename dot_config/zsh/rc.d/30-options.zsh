# Preserve the previous directory-stack and interactive editing preferences.
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS
setopt ALWAYS_TO_END AUTO_LIST AUTO_MENU COMPLETE_IN_WORD
setopt CHECK_JOBS EXTENDED_GLOB INTERACTIVE_COMMENTS LONG_LIST_JOBS
setopt MAGIC_EQUAL_SUBST NOTIFY NUMERIC_GLOB_SORT PRINT_EXIT_VALUE
setopt PROMPT_SUBST RM_STAR_WAIT TRANSIENT_RPROMPT
setopt NO_BEEP NO_HIST_BEEP NO_LIST_BEEP

# Leave command correction, case-sensitive globs and hidden-file globbing at
# their defaults. Completion can include hidden files without changing `rm *`.
autoload -Uz colors add-zsh-hook
colors
