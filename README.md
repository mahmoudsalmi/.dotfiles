# Dotfiles

Chezmoi-managed shell and application configuration, with mise for tools and
repeatable setup on Fedora, Debian/Ubuntu, Alpine, Arch, macOS, and WSL.

## Quickstart

For a fresh machine, run as your regular user (Linux needs sudo or doas):

```sh
curl -fsSL https://raw.githubusercontent.com/mahmoudsalmi/.dotfiles/main/bootstrap.sh -o bootstrap.sh
sh bootstrap.sh --dry-run
sh bootstrap.sh
exec zsh -l
```

For an existing setup, preview and run the guided updater:

```sh
mise run update --dry-run
mise run update
```

## Docs

- [Fresh install and bootstrap details](docs/bootstrap.md)
- [Mise tools, local selections, and updates](docs/mise.md)
- [Zsh modules, local overrides, and completions](docs/zsh.md)
- [Neovim configuration and dependencies](docs/neovim.md)
- [Terminals, fonts, SSH, and tmux](docs/terminals-and-tmux.md)

The legacy Stow setup is preserved on `legacy/stow`. See
[bootstrap details](docs/bootstrap.md) before selecting a different source branch.
