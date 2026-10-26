-- lua/config/plugins/format.lua
-- conform.nvim: unified format-on-save for Java, Deno, and Node TS/JS.
-- Replaces the raw BufWritePre in lsp.lua.
--
-- Formatters:
--   Java       → JDTLS (via lsp_format = "prefer")
--   Deno TS/JS → deno fmt     (only when deno.json found in project tree)
--   Node TS/JS → oxfmt (only when package.json found, no deno.json)
--   Everything else → LSP fallback if the server supports textDocument/formatting
--
-- Install:  Node projects should provide oxfmt in their local node_modules.

return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  config = function()
    local conform = require("conform")

    conform.setup({
      -- ── Per-formatter overrides ─────────────────────────────────────────────
      -- Both built-in formatters are extended with a `condition` that uses the
      -- same project-type detection as our LSP setup (ts_lsp.detect).
      formatters = {
        deno_fmt = {
          -- Only run in Deno projects (deno.json found up the tree)
          condition = function(_, ctx)
            return require("config.ts_lsp").detect(ctx.dirname).type == "deno"
          end,
        },
        oxfmt = {
          -- Only run when the Node project has oxfmt installed.
          condition = function(_, ctx)
            local project = require("config.ts_lsp").detect(ctx.dirname)
            if project.type ~= "node" then return false end
            return vim.fn.executable(project.root .. "/node_modules/.bin/oxfmt") == 1
              or vim.fn.exepath("oxfmt") ~= ""
          end,
        },
        clang_format = {
          command = "clang-format",
        },
      },

      -- ── Formatters by filetype ──────────────────────────────────────────────
      formatters_by_ft = {
        -- Java: delegate entirely to JDTLS
        java = { lsp_format = "prefer" },

        -- TS/JS: try deno_fmt first, then project-local oxfmt.
        -- stop_after_first means only one runs per save.
        typescript      = { "deno_fmt", "oxfmt", stop_after_first = true },
        typescriptreact = { "deno_fmt", "oxfmt", stop_after_first = true },
        javascript      = { "deno_fmt", "oxfmt", stop_after_first = true },
        javascriptreact = { "deno_fmt", "oxfmt", stop_after_first = true },

        -- pure c
        c = { "clang_format" },
      },

      -- ── Format on save ──────────────────────────────────────────────────────
      -- lsp_format = "fallback": for filetypes not listed above (lua, bash, …)
      -- fall back to LSP formatting if the attached server supports it.
      format_on_save = function(bufnr)
        -- Skip very large files to avoid blocking
        if vim.api.nvim_buf_line_count(bufnr) > 5000 then return end
        return { timeout_ms = 3000, lsp_format = "fallback" }
      end,
    })

    -- ── Manual format keymap ───────────────────────────────────────────────────
    vim.keymap.set({ "n", "v" }, "<leader>cf",
      function()
        conform.format({ async = true, lsp_format = "fallback" })
      end,
      { desc = "Format buffer / selection" }
    )
  end,
}
