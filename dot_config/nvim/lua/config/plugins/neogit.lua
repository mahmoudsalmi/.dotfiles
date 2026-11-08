return {
  "NeogitOrg/neogit",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "sindrets/diffview.nvim",
    "nvim-telescope/telescope.nvim",
  },
  cmd = { "Neogit", "NeogitLogCurrent", "NeogitCommit", "NeogitResetState" },
  keys = {
    { "<space>gg", "<cmd>Neogit<CR>",            desc = "Neogit: status" },
    { "<space>gc", "<cmd>Neogit commit<CR>",     desc = "Neogit: commit" },
    { "<space>gp", "<cmd>Neogit pull<CR>",       desc = "Neogit: pull" },
    { "<space>gP", "<cmd>Neogit push<CR>",       desc = "Neogit: push" },
    { "<space>gl", "<cmd>Neogit log<CR>",        desc = "Neogit: log" },
    {
      "<space>gF",
      function()
        local filename = vim.api.nvim_buf_get_name(0)
        local root = vim.fs.root(0, { ".git" })
        if filename == "" or not root then
          vim.notify("Neogit file history requires a named file inside a Git repository.", vim.log.levels.WARN)
          return
        end

        -- Neogit's file-log command uses its current repository context, which
        -- may otherwise still be Neovim's startup cwd rather than this buffer's repo.
        require("neogit.lib.git.repository").instance(root)
        vim.api.nvim_cmd({ cmd = "NeogitLogCurrent", args = { filename } }, {})
      end,
      desc = "Neogit: current file history",
    },
  },
  config = function()
    require("neogit").setup({
      integrations = {
        diffview = true,
        telescope = true,
      },
      graph_style = "unicode",
    })
  end,
}
