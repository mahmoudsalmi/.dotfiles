local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local make_entry = require "telescope.make_entry"
local conf = require "telescope.config".values

--- Telescope extension for live multi-grep
--- Prompt syntax: `<pattern>  <glob>` (separated by TWO spaces).
--- Examples:
---   TODO
---   require  *.lua
---   useState  !**/node_modules/**
local M = {}

-- Returns the closest git repo root, or falls back to cwd
local function git_root()
  local result = vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }):wait()
  if result.code == 0 then
    return vim.trim(result.stdout)
  end
  return vim.fn.getcwd()
end

local live_mutligrep = function(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or git_root()

  local finder = finders.new_async_job {
    command_generator = function(prompt)
      if not prompt or prompt == "" then
        return nil
      end

      local pieces = vim.split(prompt, "  ")
      local args = { "rg" }

      if pieces[1] and pieces[1] ~= "" then
        table.insert(args, "-e")
        table.insert(args, pieces[1])
      else
        -- no pattern yet, don't run
        return nil
      end

      if pieces[2] and pieces[2] ~= "" then
        table.insert(args, "-g")
        table.insert(args, pieces[2])
      end

      vim.list_extend(args, {
        "--color=never", "--no-heading", "--with-filename",
        "--line-number", "--column", "--smart-case", "--follow",
      })
      return args
    end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
  }

  pickers.new(opts, {
    debounce = 100,
    prompt_title = "Multi Grep (" .. opts.cwd .. ")",
    finder = finder,
    previewer = conf.grep_previewer(opts),
    sorter = require("telescope.sorters").empty(),
  }):find()
end

M.setup = function()
  vim.keymap.set("n", "<leader>fg", live_mutligrep, { desc = "Telescope: multigrep (pattern  glob)" })
end

return M
