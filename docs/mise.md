# Mise tools and updates

## Ownership

- `~/.config/mise/config.toml` is tracked by chezmoi and holds shared tool pins,
  bootstrap packages, and tasks.
- `~/.config/mise/config.local.toml` is machine-local and untracked. Bootstrap
  installs its initial chezmoi tool there; new global tool selections are routed
  there by `settings.write_targets.tools`.
- Mise owns tool installs and shims; the OS package manager supplies bootstrap
  prerequisites.

Use a local selection without changing shared dotfiles:

```sh
mise use --global --pin TOOL@VERSION
mise config ls
```

New global tools go to `config.local.toml`. Mise keeps an existing tool request
in the file that already declares it, so to locally override a tool pinned in
`config.toml`, select the local file explicitly:

```sh
mise use --path "$HOME/.config/mise/config.local.toml" --pin TOOL@VERSION
```

To promote a local choice to every machine, copy its entry into
`dot_config/mise/config.toml` in the chezmoi source and remove the local
override. Review and commit that change. `config.local.toml` is excluded from
chezmoi so it stays machine-local.

## Guided update

Preview, then run:

```sh
mise run update --dry-run
mise run update
```

The task fetches chezmoi changes without applying them, displays the diff, and
asks before applying. It installs configured tools, upgrades only versions
permitted by their requests, upgrades/reconciles declared bootstrap packages,
and updates mise itself last. Exact tool pins are not bumped automatically;
change those deliberately in the shared source and review the resulting diff.
The dry run does not fetch the remote repo or preview mise's self-update.

On a configured machine, the manual equivalent is:

```sh
chezmoi update
mise install
bat cache --build
```

## Package declarations

`[bootstrap.packages]` currently declares Linux build tools for Tree-sitter and
`btop` via Homebrew on macOS. Mise skips package managers unavailable on the
current OS. Bootstrap installs the initial system prerequisites before applying
the mise config; `mise run update` later reconciles declared packages.

On macOS, `mise run install:packages` handles `btop`; on Apple Silicon it uses
mise's Homebrew-compatible package manager, and on Intel it uses installed
Homebrew. `mise run services:macos` installs the optional launchd limits and
requires administrator privileges.

## Source workflow

```sh
chezmoi cd
git status --short
git add <specific-files>
git commit -m "Describe the change"
git push
exit
```
