-- lua/config/plugins/lint.lua
-- nvim-lint: async linting for Node TS/JS via eslint.
-- Deno diagnostics (deno lint) come from denols LSP (lint=true in init_options).
-- Java diagnostics come from JDTLS.
-- This plugin only adds eslint for Node projects.
--
-- eslint resolution order:
--   1. ./node_modules/.bin/eslint   (project-local, preferred)
--   2. eslint in PATH               (global fallback — rarely desired)
--   eslint is NOT run if node_modules/.bin/eslint is absent and nothing in PATH.

return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufWritePost", "InsertLeave" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      typescript      = { "eslint" },
      typescriptreact = { "eslint" },
      javascript      = { "eslint" },
      javascriptreact = { "eslint" },
    }

    local ts_fts = {
      typescript = true, typescriptreact = true,
      javascript = true, javascriptreact = true,
    }

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
      callback = function(args)
        local ft = vim.bo[args.buf].filetype
        if not ts_fts[ft] then return end

        -- Only lint Node projects; Deno diagnostics come from the denols LSP
        if require("config.ts_lsp").detect().type ~= "node" then return end

        -- Prefer the project-local eslint binary
        local local_bin = vim.fn.getcwd() .. "/node_modules/.bin/eslint"
        lint.linters.eslint.cmd = vim.fn.executable(local_bin) == 1
          and local_bin
          or "eslint"

        -- try_lint errors if eslint is not available; swallow gracefully
        local ok, err = pcall(lint.try_lint)
        if not ok then
          vim.notify("nvim-lint eslint: " .. err, vim.log.levels.WARN)
        end
      end,
    })

    -- Manual lint trigger
    vim.keymap.set("n", "<leader>cl",
      function()
        local ok, err = pcall(lint.try_lint)
        if not ok then vim.notify("lint: " .. err, vim.log.levels.WARN) end
      end,
      { desc = "Lint current file" }
    )
  end,
}
