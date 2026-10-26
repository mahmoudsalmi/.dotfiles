# Zsh configuration

`~/.zshrc` loads the ordered modules in `~/.config/zsh/rc.d/`, then sources
`~/.config/zsh/local.zsh` if present. The latter is excluded from chezmoi and is
the place for host-specific settings and tools. Startup does not install tools
or clone plugins. Ordered modules configure the environment, shared history,
completion, aliases, vi/fzf widgets, Starship, Atuin, and zoxide. Atuin keeps
history local with sync disabled; import prior history with `atuin import zsh`
if desired.

On macOS, Zsh detects an existing Homebrew prefix and adds its `bin`/`sbin`
behind mise shims and `~/.local/bin`. Its site-functions are added before
`compinit`. Apple Silicon, Intel, Linuxbrew, and an explicit
`HOMEBREW_PREFIX` are supported; startup checks paths but never invokes `brew`.

## Add local tool completions

`45-tool-completions.zsh` exposes `ms_add_tool_completion TOOL FUNCTION` for
local completion generators. Define a function in `~/.config/zsh/local.zsh`
that prints Zsh completion code, then register it:

```zsh
_mytool_completion() {
  command mytool completion zsh
}
ms_add_tool_completion mytool _mytool_completion
```

The generator receives the tool name as `$1`. Its output is syntax-checked and
cached lazily on first Tab, under `$XDG_CACHE_HOME/zsh/tool-completions` (or
`~/.cache/zsh/tool-completions`). The cache is invalidated when the selected
executable changes. If the tool ships a
`#compdef` completion instead of a generator, the dispatcher can discover it in
the mise install directory.

## Edit the local override

In vi insert or command mode, press **Ctrl-X**, then **Ctrl-Z** to open
`~/.config/zsh/local.zsh` in Neovim. The two-control-key sequence avoids the
`Ctrl-X` then `Z` zoxide binding. The local file is not deployed or overwritten
by chezmoi.

Other useful keybindings include Ctrl-G to open the fzf file picker in Neovim,
Ctrl-F/Ctrl-T to insert a selected path, and Ctrl-X then Ctrl-C to change to a
selected directory.
