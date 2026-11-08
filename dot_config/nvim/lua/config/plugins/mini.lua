return {
  {
    "echasnovski/mini.nvim",
    config = function()
      require("mini.statusline").setup({ use_icons = true })
    end,
  },
  {
    "echasnovski/mini.icons",
    config = function()
      require("mini.icons").setup()
    end,
  },
}
