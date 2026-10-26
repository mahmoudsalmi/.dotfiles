return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles", "DiffviewRefresh" },
  keys = {
    { "<space>gd", "<cmd>DiffviewOpen<CR>",                desc = "Diffview: open (working tree vs index)" },
    { "<space>gD", "<cmd>DiffviewClose<CR>",               desc = "Diffview: close" },
    { "<space>gh", "<cmd>DiffviewFileHistory<CR>",         desc = "Diffview: repo history" },
    { "<space>gf", "<cmd>DiffviewFileHistory %<CR>",       desc = "Diffview: current file history" },
  },
  config = function()
    require("diffview").setup({
      enhanced_diff_hl = true,
      view = {
        default      = { layout = "diff2_horizontal" },
        merge_tool   = { layout = "diff3_mixed" },
        file_history = { layout = "diff2_horizontal" },
      },
    })
  end,
}
