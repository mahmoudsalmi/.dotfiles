# Fresh install and bootstrap

## Run it

Download, inspect, preview, and run the bootstrap as your regular user:

```sh
curl -fsSL https://raw.githubusercontent.com/mahmoudsalmi/.dotfiles/main/bootstrap.sh -o bootstrap.sh
sh bootstrap.sh --dry-run
sh bootstrap.sh
exec zsh -l
```

Linux needs sudo or doas. On a fresh Mac, finish Xcode command-line tools setup
if prompted, then rerun. On Arch, update the system normally first; bootstrap
does not refresh pacman's databases or perform a full system upgrade. Alpine
needs its community repository enabled for packages such as `shadow`. Run the
Linux setup inside the WSL distribution. Terminal profiles should not force
Bash.

The default source is the `main` branch of this repository. To select
a different source explicitly:

```sh
DOTFILES_REPO=https://github.com/mahmoudsalmi/.dotfiles.git DOTFILES_BRANCH=BRANCH sh bootstrap.sh
```

An existing chezmoi checkout must already match the selected origin and branch;
bootstrap does not switch branches or update a mismatched checkout automatically.

## What bootstrap does

1. Detects the platform and installs system prerequisites, including Zsh and
   Linux compiler tools used by Neovim Tree-sitter parsers.
2. Installs mise if absent and installs the bootstrap-time chezmoi version into
   `~/.config/mise/config.local.toml`.
3. Initializes and applies the chezmoi source, backing up existing `.zshrc`,
   `.zshenv`, and `.zprofile` first.
4. Installs configured mise tools and macOS native packages.
5. Rebuilds bat's theme cache and changes the login shell to Zsh if needed.

Network access is required. Existing file conflicts may prompt during apply.
The layout assumes the default HOME and `~/.config`; custom XDG config paths or
ZDOTDIR require corresponding source-layout changes.

Alpine uses musl and receives `gcompat` for other upstream tools that need glibc
compatibility. That does not guarantee every upstream binary works on Alpine.
See [Neovim](neovim.md) for its parser/compiler requirements and platform notes.

For a configured host, use `mise run update`; do not rerun bootstrap as a routine
updater. The task previews dotfile changes before applying them.
