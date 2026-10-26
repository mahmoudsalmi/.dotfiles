-- pi-nvim-bridge: Brings pi's autocomplete into Neovim
-- Repo: https://github.com/dabstractor/pi-nvim-bridge
--
-- This plugin bridges pi's live autocomplete engine into Neovim when used as pi's
-- external editor ($EDITOR). When you press Ctrl+G in pi to open the editor,
-- you get pi's completions (slash commands, skills, @file refs, etc.) rendered
-- inside Neovim's completion menu.
--
-- Prerequisites:
-- - pi with pi-nvim-bridge extension installed ✓ (already done)
-- - Neovim ≥ 0.11 (0.12 verified)
-- - fd (optional, for @file fuzzy search)
-- - Set EDITOR=nvim in your shell or pi's settings.json

return {
  {
    "dabstractor/pi-nvim-bridge",
    lazy = false,  -- CRITICAL: must load before VimEnter so the startup shim runs first
    config = function()
      require("pi-bridge").setup({
        -- Shell completion for ! and !! lines (optional)
        shell = {
          enabled = true,          -- master switch for shell completion
          prefer = "pi",           -- "pi" | "shell" | "bash" | "/abs/path"
          drivers = {
            fish = true,
            zsh = true,
            bash = true,
          },
          warm_on_enter = false,   -- spawn the daemon at VimEnter (improves responsiveness if true)
          visual_cue = "gutter",   -- "$ " prefix on shell items | or "none"
          -- Optional: fine-tune timeouts and debouncing
          -- timeout_ms = 200,
          -- startup_timeout_ms = 500,
          -- debounce_ms = 50,
          -- max_parse_failures = 3,
        },
      })
    end,
  }
}
