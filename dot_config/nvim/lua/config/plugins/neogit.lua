return {
  "NeogitOrg/neogit",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "sindrets/diffview.nvim",
    "nvim-telescope/telescope.nvim",
  },
  cmd = "Neogit",
  keys = {
    { "<space>gg", "<cmd>Neogit<CR>",            desc = "Neogit: status" },
    { "<space>gc", "<cmd>Neogit commit<CR>",     desc = "Neogit: commit" },
    { "<space>gp", "<cmd>Neogit pull<CR>",       desc = "Neogit: pull" },
    { "<space>gP", "<cmd>Neogit push<CR>",       desc = "Neogit: push" },
    { "<space>gl", "<cmd>Neogit log<CR>",        desc = "Neogit: log" },
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
