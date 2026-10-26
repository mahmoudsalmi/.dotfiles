return {
  {
    "uga-rosa/translate.nvim",
    ft = { "txt", "markdown", "lua", "python", "*" }, -- lazy-load as desired
    dependencies = { "nvim-lua/plenary.nvim" },       -- required by some output options
    config = function()
      require("translate").setup({
        -- You can explicitly choose translate-shell as backend:
        default = { command = "translate_shell" },
        -- Optionally configure default output method:
        preset = { output = { split = { append = false } } },
      })

      local map = vim.keymap.set
      local opts = { noremap = true, silent = true }

      -- Translate word or selection into French in a floating window
      map("n", "<leader>tf", "<Cmd>Translate FR -output=floating<CR>", opts)
      map("v", "<leader>tf", "<Cmd>Translate FR -output=floating<CR>", opts)
      map("v", "<leader>cf", "<Cmd>Translate FR -output=split<CR>", opts)

      -- Translate word or selection into English in a floating window
      map("n", "<leader>te", "<Cmd>Translate EN -output=floating<CR>", opts)
      map("v", "<leader>te", "<Cmd>Translate EN -output=floating<CR>", opts)
      map("v", "<leader>ce", "<Cmd>Translate EN -output=split<CR>", opts)

      -- Translate word or selection into Arabic in a floating window
      map("n", "<leader>ta", "<Cmd>Translate AR -output=floating<CR>", opts)
      map("v", "<leader>ta", "<Cmd>Translate AR -output=floating<CR>", opts)
    end,
  },
}
