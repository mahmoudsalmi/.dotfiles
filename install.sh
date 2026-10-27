#!/bin/sh
# Lightweight dotfiles setup for devcontainers (DevPod, Codespaces, VS Code).
# Run automatically by the tool from the cloned dotfiles repository, as the
# container user. Supports apt, dnf and apk images. See bootstrap.sh for hosts.
set -eu

log() { printf '==> %s\n' "$*"; }
fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }
has() { command -v "$1" >/dev/null 2>&1; }
admin() {
    if [ "$(id -u)" = 0 ]; then "$@"
    elif has sudo; then sudo "$@"
    elif has doas; then doas "$@"
    else fail "Need root, sudo or doas to run: $*"
    fi
}

: "${HOME:?HOME must be set}"
src=$(cd "$(dirname "$0")" && pwd)
[ -d "$src/.git" ] || fail "$src is not a git checkout of the dotfiles."

# Only install what is missing. A compiler (no make, no full build chain) is
# enough for Neovim to build its Tree-sitter parsers.
pkgs_missing() { for t in git curl zsh gcc; do has "$t" || return 0; done; return 1; }
if pkgs_missing || { has apk && ! has chsh; }; then
    log 'Installing prerequisites'
    if has apt-get; then
        admin apt-get update
        admin apt-get install -y --no-install-recommends \
            git curl ca-certificates tar gzip zsh passwd gcc libc6-dev
    elif has dnf; then
        set -- git ca-certificates tar gzip zsh util-linux-user gcc
        has curl || set -- "$@" curl   # keep Fedora's curl-minimal if present
        admin dnf install -y "$@"
    elif has apk; then
        # shadow: chsh. gcompat: glibc-only tools such as chezmoi. musl-dev: C headers.
        admin apk add --no-cache git bash curl ca-certificates tar gzip zsh \
            shadow musl-utils gcompat gcc musl-dev
    else
        fail 'Supported package managers: apt-get, dnf, apk.'
    fi
fi

bin_dir="$HOME/.local/bin"
export PATH="$bin_dir:$PATH"
mkdir -p "$bin_dir"

if ! has mise; then
    log 'Installing mise'
    tmp=$(mktemp)
    trap 'rm -f "$tmp"' 0
    curl -fsSL https://mise.run -o "$tmp"
    MISE_INSTALL_PATH="$bin_dir/mise" sh "$tmp"
fi

# Work outside the repository so its config cannot override the global one.
cd "$HOME"
mkdir -p "$HOME/.config/mise"
log 'Installing chezmoi'
mise use --path "$HOME/.config/mise/config.local.toml" --pin chezmoi@latest

# Reuse the checkout made by the devcontainer tool as the chezmoi source.
default_src=$(mise exec -- chezmoi source-path)
if [ ! -e "$default_src" ]; then
    mkdir -p "$(dirname "$default_src")"
    ln -s "$src" "$default_src"
fi

log 'Applying dotfiles'
# No TTY: chezmoi skips prompts (terminal configs are not installed).
mise exec -- chezmoi init --apply </dev/null

log 'Installing tools'
mise install
if mise which bat >/dev/null 2>&1; then mise exec -- bat cache --build; fi

if zsh_path=$(command -v zsh) && grep -Fqx "$zsh_path" /etc/shells; then
    user=$(id -un)
    current=$(getent passwd "$user" | cut -d: -f7)
    if [ "$current" != "$zsh_path" ]; then
        log "Setting login shell to $zsh_path"
        admin chsh -s "$zsh_path" "$user" || log 'chsh failed; continuing.'
    fi
fi
log 'Done. Open a new shell, or run: exec zsh -l'
