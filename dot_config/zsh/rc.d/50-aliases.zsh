if (( $+commands[lsd] )); then
  alias ls='lsd --group-directories-first'
  alias la='lsd -al --group-directories-first'
  alias ll='lsd -l --group-directories-first'
  alias lt='lsd -lt --group-directories-first'
  alias l='lsd -alt --group-directories-first'
elif (( $+commands[eza] )); then
  alias ls='eza --group-directories-first'
  alias la='eza -al --group --group-directories-first'
  alias ll='eza -l --group --group-directories-first'
  alias lt='eza -l --sort=newest --group --group-directories-first'
  alias l='eza -al --sort=newest --group --group-directories-first'
else
  # Common flags work with GNU, BSD (macOS), and BusyBox ls.
  alias la='ls -al'
  alias ll='ls -l'
  alias lt='ls -lt'
  alias l='ls -alt'
fi

if (( $+commands[nvim] )); then
  alias vi=nvim
  alias vim=nvim
fi
alias :q=exit
(( $+commands[pi] )) && alias pi='TMPDIR=/tmp pi'
if (( $+commands[coach] )); then
  alias c-tldr='coach tldr'
  alias c-snip='coach snippet'
fi

# Use null-delimited file names, preserve spaces, and do nothing on empty diff.
if (( $+commands[git] && $+commands[bat] )); then
  batdiff() {
    local file
    local -a files
    while IFS= read -r -d '' file; do
      files+=("$file")
    done < <(git diff --name-only --relative --diff-filter=d -z)
    (( ${#files} )) && bat --diff -- "${files[@]}"
  }
fi
if (( $+commands[bat] )); then
  t() { tail -f -- "$@" | bat --paging=never --language=log; }
fi
true
