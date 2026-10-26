return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("gitsigns").setup({
      signs = {
        add          = { text = "│" },
        change       = { text = "│" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "~" },
        untracked    = { text = "┆" },
      },
      current_line_blame = false, -- toggle with <space>gb
      current_line_blame_opts = {
        delay = 300,
        virt_text_pos = "eol",
      },
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        -- Navigation between hunks
        map("n", "]c", function()
          if vim.wo.diff then return "]c" end
          vim.schedule(function() gs.next_hunk() end)
          return "<Ignore>"
        end, "Next hunk")
        map("n", "[c", function()
          if vim.wo.diff then return "[c" end
          vim.schedule(function() gs.prev_hunk() end)
          return "<Ignore>"
        end, "Prev hunk")

        -- Hunk actions (mnemonic: <space>h…)
        map("n", "<space>hs", gs.stage_hunk,           "Stage hunk")
        map("n", "<space>hr", gs.reset_hunk,           "Reset hunk")
        map("v", "<space>hs", function() gs.stage_hunk { vim.fn.line("."), vim.fn.line("v") } end, "Stage selection")
        map("v", "<space>hr", function() gs.reset_hunk { vim.fn.line("."), vim.fn.line("v") } end, "Reset selection")
        map("n", "<space>hS", gs.stage_buffer,         "Stage buffer")
        map("n", "<space>hu", gs.undo_stage_hunk,      "Undo stage hunk")
        map("n", "<space>hR", gs.reset_buffer,         "Reset buffer")
        map("n", "<space>hp", gs.preview_hunk,         "Preview hunk")
        map("n", "<space>hd", gs.diffthis,             "Diff against index")
        map("n", "<space>hD", function() gs.diffthis("~") end, "Diff against last commit")

        -- Blame
        map("n", "<space>gb", gs.toggle_current_line_blame, "Toggle line blame")
        map("n", "<space>gB", function() gs.blame_line { full = true } end, "Blame line (full)")

        -- Text object: select hunk
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select hunk")
      end,
    })
  end,
}
