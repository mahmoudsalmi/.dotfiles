#!/bin/sh
# Bootstrap user tools on Fedora, Debian/Ubuntu, Alpine, Arch, macOS and WSL.
# Restore dotfiles and tools. Run as your regular user: sh bootstrap.sh [--dry-run]
# Override the source with DOTFILES_REPO and DOTFILES_BRANCH if needed.
set -eu

log() { printf '%s\n' "$*"; }
fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }
has() { command -v "$1" >/dev/null 2>&1; }
run() {
    if [ "$dry_run" = yes ]; then
        printf '[dry-run]'
        for arg do printf ' <%s>' "$arg"; done
        printf '\n'
    else
        "$@"
    fi
}
admin() {
    if [ "$dry_run" = yes ]; then
        log "[dry-run] sudo $*"
    else
        if has sudo; then
            sudo "$@"
        elif has doas; then
            doas "$@"
        else
            fail 'Configure sudo or doas for your user before installing system prerequisites.'
        fi
    fi
}

dry_run=no
case $# in
    0) ;;
    1)
        case $1 in
            --dry-run) dry_run=yes ;;
            --help|-h) log 'Usage: sh bootstrap.sh [--dry-run]'; exit 0 ;;
            *) fail "Unknown option: $1" ;;
        esac ;;
    *) fail 'Usage: sh bootstrap.sh [--dry-run]' ;;
esac

[ "$(id -u)" != 0 ] || fail 'Run this script as your regular user, without sudo.'
: "${HOME:?HOME must be set}"
case $HOME in /*) ;; *) fail 'HOME must be an absolute path.' ;; esac

os=$(uname -s)
case $os in
    Darwin)
        log 'Detected macOS (using the system Zsh).'
        # Git may need Apple's command line developer tools on a fresh Mac.
        if [ "$dry_run" = no ]; then
            xcode-select -p >/dev/null 2>&1 || {
                xcode-select --install || :
                fail 'Complete the Apple command line tools installation, then rerun.'
            }
        fi
        for tool in git curl zsh chsh; do
            has "$tool" || fail "Required macOS tool is missing: $tool"
        done
        ;;
    Linux)
        case $(uname -r) in
            *[Mm]icrosoft*|*WSL*) log 'Detected Linux under WSL.' ;;
            *) log 'Detected Linux.' ;;
        esac
        # Detect the distribution's package manager; no Homebrew needed on Linux.
        if has apk; then
            log 'Prerequisites: apk add --no-cache git bash curl ca-certificates tar gzip zsh shadow musl-utils gcompat'
            # shadow provides chsh; musl-utils provides getent.
            # Some mise/aqua recipes select glibc binaries, including chezmoi.
            # gcompat supplies the glibc loader/API compatibility on musl.
            # The official mise installer detects musl and selects its musl build.
            admin apk add --no-cache git bash curl ca-certificates tar gzip zsh shadow musl-utils gcompat
        elif has pacman; then
            log 'Prerequisites: pacman -S --needed git curl ca-certificates tar gzip zsh util-linux'
            # Use the existing package database; do not introduce a partial upgrade
            # with -Sy or silently perform a full system upgrade with -Syu.
            admin pacman -S --needed git curl ca-certificates tar gzip zsh util-linux
        elif has dnf; then
            # Fedora may already provide curl through curl-minimal.
            # Do not replace a working provider with the conflicting curl package.
            set -- git ca-certificates tar gzip zsh util-linux-user
            if ! has curl; then set -- "$@" curl; fi
            log "Prerequisites: dnf install -y $*"
            admin dnf install -y "$@"
        elif has apt-get; then
            log 'Prerequisites: apt-get install git curl zsh passwd'
            admin apt-get update
            admin apt-get install -y git curl ca-certificates tar gzip zsh passwd
        else
            fail 'Supported Linux package managers: apk, pacman, dnf, apt-get.'
        fi
        ;;
    *) fail "Unsupported OS: $os (use Linux, macOS, or WSL)." ;;
esac

# Keep the same installation paths on every platform.
bin_dir="$HOME/.local/bin"
export PATH="$bin_dir:$PATH"
run mkdir -p "$bin_dir"

if [ "$dry_run" = yes ]; then
    log "[dry-run] Install missing mise into $bin_dir using its official installer."
else
    tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' 0
    trap 'exit 1' HUP INT TERM
    if ! has mise; then
        log 'Installing mise...'
        curl -fsSL https://mise.run -o "$tmp_dir/mise.sh"
        MISE_INSTALL_PATH="$bin_dir/mise" sh "$tmp_dir/mise.sh"
    fi
    mise --version
fi

# Work outside the cloned repository so its project config cannot override the
# user-global chezmoi selection. No shell activation is required for mise exec.
run cd "$HOME"
log 'Installing and recording chezmoi through mise...'
run mise use --global --pin chezmoi@latest
run mise exec -- chezmoi --version

# Restore the migration branch; never apply the old Stow main branch by mistake.
dotfiles_repo=${DOTFILES_REPO:-https://github.com/mahmoudsalmi/.dotfiles.git}
dotfiles_branch=${DOTFILES_BRANCH:-migrate/chezmoi}
if [ "$dry_run" = no ]; then
    source_dir=$(mise exec -- chezmoi source-path)
    [ -n "$source_dir" ] || fail 'chezmoi did not report a source directory.'
    if [ -e "$source_dir/.git" ]; then
        current_repo=$(git -C "$source_dir" remote get-url origin 2>/dev/null || :)
        current_branch=$(git -C "$source_dir" symbolic-ref --short HEAD 2>/dev/null || :)
        [ "$current_repo" = "$dotfiles_repo" ] && [ "$current_branch" = "$dotfiles_branch" ] ||
            fail 'Existing chezmoi repository/branch differs. Select it explicitly before bootstrapping.'
    fi
fi
run mise exec -- chezmoi init --branch "$dotfiles_branch" "$dotfiles_repo"

# Back up existing shell entry files once before chezmoi applies its versions.
for entry in "${ZDOTDIR:-$HOME}/.zshrc" "${ZDOTDIR:-$HOME}/.zshenv" "${ZDOTDIR:-$HOME}/.zprofile"; do
    if [ "$dry_run" = yes ]; then
        log "[dry-run] Back up $entry if present and not already backed up."
    elif [ -e "$entry" ] && [ ! -e "$entry.pre-bootstrap" ]; then
        cp -p "$entry" "$entry.pre-bootstrap"
    fi
done
run mise exec -- chezmoi apply

# The restored user-global config now declares the complete pinned tool list.
run mise install
if [ "$os" = Darwin ]; then
    run mise run install:packages
fi
if [ "$dry_run" = yes ]; then
    run mise exec -- bat cache --build
elif mise which bat >/dev/null 2>&1; then
    mise exec -- bat cache --build
fi

if [ "$dry_run" = yes ]; then
    log '[dry-run] Read the account login shell; use chsh if it differs from Zsh.'
else
    zsh_path=$(command -v zsh)
    grep -Fqx "$zsh_path" /etc/shells || fail "$zsh_path is not listed in /etc/shells."
    username=$(id -un)
    case $os in
        Darwin) current_shell=$(dscl . -read "/Users/$username" UserShell | awk '{print $2}') ;;
        Linux) current_shell=$(getent passwd "$username" | cut -d: -f7) ;;
    esac
    [ -n "$current_shell" ] || fail 'Could not determine the account login shell.'
    if [ "$current_shell" != "$zsh_path" ]; then
        log "Changing $username's login shell to $zsh_path (your password may be requested)."
        chsh -s "$zsh_path"
    else
        log "Zsh is already your login shell: $zsh_path"
    fi
fi

if [ "$dry_run" = yes ]; then
    log 'Dry-run complete; no changes made.'
else
    log 'Bootstrap complete. Open a new login session, or run: exec zsh -l'
fi
log 'Next checks: mise --version; chezmoi --version; printf "%s\n" "$ZSH_VERSION"'
