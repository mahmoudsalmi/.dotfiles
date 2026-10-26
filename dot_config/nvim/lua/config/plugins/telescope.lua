return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require('telescope').setup {
        pickers = {
          find_files = {
            theme = "ivy",
            follow = true,
          }
        },
      }

      -- Returns the closest git repo root, or falls back to cwd
      local function git_root()
        local result = vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }):wait()
        if result.code == 0 then
          return vim.trim(result.stdout)
        end
        return vim.fn.getcwd()
      end

      vim.keymap.set("n", "<space>fd", function()
        require("telescope.builtin").find_files({
          cwd = git_root(),
          follow = true,
        })
      end)
      vim.keymap.set("n", "<space>ff", function()
        require("telescope.builtin").live_grep({
          cwd = git_root(),
          follow = true,
        })
      end)
      vim.keymap.set("n", "<space>fh", require("telescope.builtin").help_tags)
      vim.keymap.set("n", "<space>fb", require("telescope.builtin").buffers, { desc = "Telescope: buffers" })
      vim.keymap.set("n", "<space>en", function()
        require("telescope.builtin").find_files {
          cwd = vim.fn.stdpath("config"),
          follow = true
        }
      end)
      vim.keymap.set("n", "<space>ep", function()
        require("telescope.builtin").find_files {
          cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")
        }
      end)

      require "config.telescope.multigrep".setup()
    end
  }
}
