-- ── Neovim 0.12-dev compat ──────────────────────────────────────────────────
-- Some 0.12-dev builds expose vim.text (table) but not vim.text.diff yet.
-- conform.nvim branches on has("nvim-0.12") and calls vim.text.diff, which
-- crashes. Bridge it to the still-present vim.diff until the build catches up.
if vim.fn.has("nvim-0.12") == 1
  and type(vim.text) == "table"
  and vim.text.diff == nil
  and type(vim.diff) == "function"
then
  vim.text.diff = vim.diff
end

-- Disable unused providers
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

require("config.lazy")
require("config.treesitter_compat")

local set = vim.opt
local tabstop = 2

set.shiftwidth = tabstop
set.tabstop = tabstop
set.softtabstop = tabstop
set.expandtab = true
set.number = true
set.relativenumber = true
set.clipboard = "unnamedplus"

set.foldmethod = "expr"
set.foldexpr = "v:lua.vim.treesitter.foldexpr()"
set.foldcolumn = "0"
set.foldlevel = 99
set.foldlevelstart = 99
set.foldtext = ""
set.foldnestmax = 4

vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('ms-term-open', { clear = true }),
  callback = function()
    vim.opt.number = false
    vim.opt.relativenumber = false
  end,
})

vim.keymap.set("n", "<space><space>x", "<cmd>source %<CR>")
vim.keymap.set("n", "<space>x", ":.lua<CR>")
vim.keymap.set("v", "<space>x", ":lua<CR>")

vim.keymap.set("n", "<M-j>", ":cnext<CR>")
vim.keymap.set("n", "<M-k>", ":cprev<CR>")

-- Buffer navigation
vim.keymap.set("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<space>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })
vim.keymap.set("n", "<space>bb", "<cmd>b#<CR>", { desc = "Alternate buffer" })

vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>")

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (coping) text',
  group = vim.api.nvim_create_augroup('ms-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- open small terminal
vim.keymap.set("n", "<space>st", function()
  vim.cmd.vnew()
  vim.cmd.term()
  vim.cmd.wincmd("J")
  vim.api.nvim_input('i')
  vim.api.nvim_win_set_height(0, 10)
end)
