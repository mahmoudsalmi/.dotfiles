#!/bin/sh
# Review dotfile updates, then update configured tools and native packages.
set -eu

case $# in
    0) dry_run=no ;;
    1)
        if [ "$1" = --dry-run ]; then
            dry_run=yes
        else
            printf 'Usage: mise run update [--dry-run]\n' >&2
            exit 2
        fi
        ;;
    *) printf 'Usage: mise run update [--dry-run]\n' >&2; exit 2 ;;
esac

if [ "$dry_run" = yes ]; then
    printf '%s\n' 'Dry run: no repository fetch, apply, package changes, or self-update.'
    chezmoi diff
    mise -C "$HOME" install --dry-run
    mise upgrade --global --dry-run
    mise -C "$HOME" bootstrap packages upgrade --dry-run
    mise -C "$HOME" bootstrap packages apply --dry-run
    exit 0
fi

# Fetch changes without deploying them so the user can review first.
chezmoi update --apply=false
status=$(chezmoi status)
if [ -n "$status" ]; then
    printf '%s\n' 'Dotfile changes available:'
    chezmoi diff
    printf 'Apply these dotfile changes? [y/N] '
    answer=n
    IFS= read -r answer || :
    case $answer in
        y|Y|yes|YES|Yes) chezmoi apply ;;
        *) printf '%s\n' 'Skipped chezmoi apply; the source repo was updated.' ;;
    esac
else
    printf '%s\n' 'Dotfiles are already up to date.'
fi

# Install versions declared by the applied config, then upgrade tools only
# within their configured version ranges. Exact pins are deliberately unchanged.
mise -C "$HOME" install
mise upgrade --global

# Upgrade declared native packages and install any newly declared ones.
mise -C "$HOME" bootstrap packages upgrade --yes
mise -C "$HOME" bootstrap packages apply --yes
# Covers the Intel Mac Homebrew fallback; no-op on non-Darwin platforms.
sh "${XDG_CONFIG_HOME:-$HOME/.config}/mise/scripts/install-packages.sh"

# Update mise itself last so the rest of this task uses one mise version.
mise self-update --no-plugins
