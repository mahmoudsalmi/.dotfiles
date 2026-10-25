# Dotfiles — chezmoi + mise

Portable shell configuration for Fedora, Debian/Ubuntu, Alpine, Arch Linux,
macOS, and WSL. Zsh configuration uses Zsh syntax; installation/helper scripts
use POSIX shell and `.sh` filenames. Upstream TPM/plugins require system Bash
(included by this bootstrap on Alpine; normally part of other supported OSes).

## Fresh installation

The migration currently lives on **migrate/chezmoi**. `main` still holds the
previous Stow setup. Publish the migration branch before using this procedure
on another machine.

Download the script, inspect it, preview and run it as your regular user:

```sh
curl -fsSL https://raw.githubusercontent.com/mahmoudsalmi/.dotfiles/migrate/chezmoi/bootstrap.sh -o bootstrap.sh
sh bootstrap.sh --dry-run
sh bootstrap.sh
exec zsh -l
```

Linux requires a user with sudo or doas privileges. On a fresh Mac, complete
Apple command line tools installation if requested, then rerun. On Arch,
update your system normally before bootstrapping; the script does not perform
a full system upgrade or refresh pacman's databases. On Alpine enable your
release's community repository for shadow. The bootstrap also installs
`gcompat`: some mise-managed release binaries require the glibc loader, while
Alpine uses musl. This compatibility layer does not guarantee every upstream
binary will work; the fresh-install test must still validate the full toolset.
Run inside the Linux distribution
for WSL. Custom terminal profiles must not explicitly force Bash.

The bootstrap:

1. Detects the OS/package manager and installs prerequisites and system Zsh.
2. Installs mise if absent, then installs chezmoi through mise.
3. Initializes chezmoi from this repository's migration branch. An existing
   checkout must match the requested origin URL and branch; it is not pulled
   or switched automatically.
4. Backs up existing `.zshrc`/`.zshenv`/`.zprofile` once, then applies configuration,
   including pinned Zsh and tmux plugin archives.
5. Runs `mise install` against the restored global tool configuration.
6. Installs macOS native packages with `mise run install:packages` (btop via
   Homebrew-compatible packages on Apple Silicon; installed Homebrew on Intel).
7. Rebuilds bat's theme cache when bat is installed.
8. Changes your account's login shell to Zsh if needed.

Existing conflicting files may prompt during chezmoi apply. Network access is
needed for installers, repository cloning, plugins and tools. The supported
bootstrap layout uses default HOME dotfiles and `~/.config`; custom XDG config
locations or ZDOTDIR require corresponding changes to chezmoi's source layout.
Availability of individual tools' binaries/build prerequisites varies by OS;
the bootstrap stops and reports failures rather than hiding them.

To select a different source explicitly:

```sh
DOTFILES_REPO=https://github.com/mahmoudsalmi/.dotfiles.git DOTFILES_BRANCH=main sh bootstrap.sh
```

Use that only once `main` contains the chezmoi migration. After merging, update
the bootstrap's default branch and the raw-download URL above in the same PR.
The bootstrap initially resolves the latest chezmoi; the restored mise config
then determines the tool versions used by the completed installation.

## Ownership

| Component | Owner |
| --- | --- |
| Prerequisites and login shell | Bootstrap + OS package manager |
| Executables and pinned versions | mise (`~/.config/mise/config.toml`) |
| Configuration source and deployment | chezmoi |
| Pinned Zsh and tmux plugin sources | chezmoi external archive manifests |
| History, caches, saved sessions and local overrides | Local machine state |

Do not use TPM's install/update shortcuts for the plugins owned by chezmoi.
Update their pinned archive commits and apply instead. Nerd Fonts must be
configured in the terminal that renders the session, including over SSH.

## Everyday workflow

```sh
chezmoi edit ~/.zshrc
chezmoi diff
chezmoi apply
```

When changing tool versions, update mise then import its updated configuration:

```sh
mise use --global --pin TOOL@VERSION
chezmoi add ~/.config/mise/config.toml
```

Commit and push from the source repository:

```sh
chezmoi cd
git status --short
git add <specific-changed-files>
git commit -m "Describe the change"
git push
exit
```

On another already configured machine, update and restore tools explicitly:

```sh
chezmoi update
mise install
bat cache --build
```

This repository excludes `bootstrap.sh` and `README.md` from home deployment
using `.chezmoiignore`. Machine history and plugin session snapshots are not
configuration to commit. The legacy `tm` helper remains until plugin-based
restoration has been verified after reboot.

## SSH and tmux

`.zshenv` exposes mise shims to non-interactive commands:

```sh
ssh -t machine tmux
```

`.zprofile` reapplies that PATH setup after system login profiles, which can
reset PATH on Alpine.

Zsh modules cover environment, shared history, completions, aliases, vi/fzf
widgets, Starship, Atuin and zoxide. Plugins load from local files; startup
does not clone repositories.

Atuin uses local history with automatic sync disabled. Import existing history
explicitly with `atuin import zsh` after the first interactive Zsh session.

Tmux resurrect saves with prefix then Shift-W and restores with prefix then
Shift-E. Continuum saves every ten minutes and restores when a new tmux server
starts. The restore setting does not itself start tmux at OS boot, and it does
not preserve arbitrary process memory or unsaved editor state.

## Homebrew on macOS

Zsh detects an existing Homebrew prefix and adds its `bin`/`sbin` to PATH,
behind mise shims and `~/.local/bin`. Its Zsh site-functions directory is added
before compinit. Apple Silicon, Intel, Linuxbrew and an explicit
`HOMEBREW_PREFIX` are supported. Startup uses filesystem checks only.

`btop` remains pinned under mise `[tools]` on Linux. On macOS,
`[bootstrap.packages]` declares `brew:btop`; install it explicitly with:

```sh
mise run install:packages
```

On Apple Silicon this runs `mise bootstrap packages apply --manager brew --yes`.
Mise installs Homebrew-compatible bottles into `/opt/homebrew`, even without
the `brew` executable. These packages have no mise shims. On Intel Macs, where
mise's native brew manager is unavailable, the task uses installed Homebrew.
Homebrew's current btop formula is installed, rather than pinning Linux's
version. Existing installations are preserved; no automatic upgrades occur.
The bootstrap runs this task on macOS; `mise install` alone does not.
