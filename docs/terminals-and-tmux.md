# Terminals, fonts, SSH, and tmux

## Terminal configs

Terminal emulator configs are optional during chezmoi init: Alacritty, Ghostty,
Kitty, and WezTerm. Set the terminal that renders the session—including the
remote terminal used over SSH—to a Nerd Font for icons and symbols.

## Zsh and remote commands

`.zshenv` exposes mise shims to non-interactive commands; `.zprofile` reapplies
the PATH after system login profiles that may reset it (notably Alpine). This
supports commands such as:

```sh
ssh -t machine tmux
```

## Tmux persistence

Tmux uses TPM plugin archives pinned by chezmoi. Do not use TPM's install/update
shortcuts; update the pinned archive commits in the source and apply them.

Tmux-resurrect saves a session with prefix then Shift-W and restores with prefix
then Shift-E. Continuum saves every ten minutes and restores when a new tmux
server starts. Restore does not start tmux at OS boot and cannot preserve
arbitrary process memory or unsaved editor state. Session history and saved
session snapshots are machine-local and excluded from chezmoi.
