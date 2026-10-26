# Neovim

The configuration is deployed to `~/.config/nvim`. It uses lazy.nvim with
plugins pinned by `lazy-lock.json`; the first Neovim launch downloads those
plugins. The config's Neovim version is managed in mise.

On Linux, bootstrap installs a C toolchain so the configured Tree-sitter parsers
can compile. Mac uses Xcode command-line tools. Parsers install when the
Treesitter plugin loads and a compiler is available; without one, startup stays
usable but parser features are unavailable.

Language servers and formatters are project/tool dependent. JDTLS,
TypeScript-language-server, `clangd`, and `clang-format` are optional and must be
installed/configured where needed. Markdown preview also needs Node.js/npm; its
plugin build is skipped with a warning when npm is unavailable. `render-markdown`
uses Tree-sitter.

The pinned config includes a Neovim 0.12 compatibility shim for Tree-sitter
query captures and Conform. Some plugins or binaries may need platform-specific
handling; on Alpine, the current upstream mise Neovim binary may not run under
musl even with `gcompat`. Alpine support is still being worked through; don't
replace the mise-managed Neovim with the APK package unless you explicitly want
to diverge from the version-managed setup.
