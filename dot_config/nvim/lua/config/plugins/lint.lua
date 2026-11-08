-- lua/config/plugins/lint.lua
-- nvim-lint: use project-local oxlint (preferred) or eslint for Node TS/JS.
-- Deno diagnostics come from denols; Java diagnostics come from JDTLS.

return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufWritePost", "InsertLeave" },
  config = function()
    local lint = require("lint")

    -- Select the linter dynamically per project so Node projects without either
    -- executable don't try to spawn a missing global `eslint`.

    local ts_fts = {
      typescript = true, typescriptreact = true,
      javascript = true, javascriptreact = true,
    }

    local function find_project_bin(root, name)
      local dir = root
      while dir and dir ~= "" do
        local candidate = vim.fs.joinpath(dir, "node_modules", ".bin", name)
        if vim.fn.executable(candidate) == 1 then
          return candidate
        end

        local parent = vim.fs.dirname(dir)
        if parent == dir then break end
        dir = parent
      end
    end

    local function lint_node_buffer(bufnr)
      if not ts_fts[vim.bo[bufnr].filetype] then return end

      local filename = vim.api.nvim_buf_get_name(bufnr)
      local start_dir = filename ~= "" and vim.fs.dirname(filename) or vim.fn.getcwd()
      local project = require("config.ts_lsp").detect(start_dir)
      if project.type ~= "node" then return end

      -- In pnpm workspaces, tools are often installed only at the workspace
      -- root rather than in the individual package's node_modules/.bin.
      local selected
      for _, name in ipairs({ "oxlint", "eslint" }) do
        local path = find_project_bin(project.root, name)
        if path then
          selected = { name = name, path = path }
          break
        end
      end
      if not selected then
        for _, name in ipairs({ "oxlint", "eslint" }) do
          local path = vim.fn.exepath(name)
          if path ~= "" then
            selected = { name = name, path = path }
            break
          end
        end
      end
      if not selected then
        vim.notify_once(
          "nvim-lint: oxlint or eslint not found in this Node project or its parent workspace.",
          vim.log.levels.WARN
        )
        return
      end

      lint.linters[selected.name].cmd = selected.path
      lint.try_lint(selected.name, { cwd = project.root })
    end

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
      callback = function(args)
        lint_node_buffer(args.buf)
      end,
    })

    -- Manual lint trigger
    vim.keymap.set("n", "<leader>cl", function()
      lint_node_buffer(vim.api.nvim_get_current_buf())
    end, { desc = "Lint current file" })
  end,
}
