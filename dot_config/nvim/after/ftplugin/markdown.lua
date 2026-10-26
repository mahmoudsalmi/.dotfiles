-- Insert date in Normal mode
vim.keymap.set("n", "<leader>d", function()
  local date = os.date("%Y-%m-%d")
  vim.api.nvim_put({date}, "c", true, true)
end, { desc = "Insert current date" })

-- Insert datetime in Normal mode (e.g., press <leader>d)
vim.keymap.set("n", "<leader>t", function()
  local date = os.date("%Y-%m-%dT%H:%M:%S")
  vim.api.nvim_put({date}, "c", true, true)
end, { desc = "Insert current datetime" })

-- Insert date directly in Insert mode
vim.keymap.set("i", "<C-f>", function()
  return os.date("%Y-%m-%d")
end, { expr = true, desc = "Insert current date in insert mode" })

-- Insert datetime directly in Insert mode
vim.keymap.set("i", "<C-d>", function()
  return os.date("%Y-%m-%dT%H:%M:%S")
end, { expr = true, desc = "Insert current datetime in insert mode" })
