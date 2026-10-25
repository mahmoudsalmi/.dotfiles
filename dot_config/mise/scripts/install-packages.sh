#!/bin/sh
# Native packages are installed explicitly, never by interactive shell startup.
set -eu
case $(uname -s) in
    Darwin) ;;
    *) exit 0 ;;
esac

case $(uname -m) in
    arm64|aarch64)
        # Uses Homebrew-compatible bottles and receipts in /opt/homebrew.
        mise bootstrap packages apply --manager brew --yes
        ;;
    x86_64)
        # mise's native brew package manager currently skips Intel Macs.
        brew_bin=$(command -v brew || :)
        if [ -z "$brew_bin" ] && [ -n "${HOMEBREW_PREFIX:-}" ] &&
            [ -x "$HOMEBREW_PREFIX/bin/brew" ]; then
            brew_bin="$HOMEBREW_PREFIX/bin/brew"
        fi
        if [ -z "$brew_bin" ] && [ -x /usr/local/bin/brew ]; then
            brew_bin=/usr/local/bin/brew
        fi
        if [ -z "$brew_bin" ]; then
            printf '%s\n' 'Install Homebrew on this Intel Mac, then rerun: mise run install:packages' >&2
            exit 1
        fi
        if ! "$brew_bin" list --formula btop >/dev/null 2>&1; then
            "$brew_bin" install btop
        fi
        ;;
    *) printf '%s\n' 'Unsupported macOS architecture for native packages.' >&2; exit 1 ;;
esac
