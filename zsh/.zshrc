# OPENSPEC:START
# OpenSpec shell completions configuration
fpath=("/Users/SSAL/.zsh/completions" $fpath)
autoload -Uz compinit
compinit
# OPENSPEC:END

export MS_ZSH_CONFIG=$HOME/.config/zsh
source $MS_ZSH_CONFIG/init.zsh


# >>> dev-coach aliases >>>
alias c-tldr='coach tldr'
alias c-snip='coach snippet'
# <<< dev-coach aliases <<<

# bun completions
[ -s "/Users/SSAL/.bun/_bun" ] && source "/Users/SSAL/.bun/_bun"
