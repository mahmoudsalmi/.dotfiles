local state = {
  floating = {
    buf = -1,
    win = -1,
  }
}

local function create_floating_window(opts)
  opts = opts or {}                                           -- Options table, default to empty
  local width = opts.width or math.floor(vim.o.columns * 0.8) -- 80% of screen width
  local height = opts.height or math.floor(vim.o.lines * 0.8) -- 80% of screen height

  -- Calculate centered position
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create a buffer

  local buf = nil
  if vim.api.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vim.api.nvim_create_buf(false, true)
  end

  -- Set window options
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",  -- No borders, no extra UI
    border = "rounded", -- Add rounded borders (optional)
  })

  return { buf = buf, win = win }
end

vim.api.nvim_create_user_command("FloatTerm", function()
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    state.floating = create_floating_window({ buf = state.floating.buf })
    if vim.bo[state.floating.buf].buftype ~= "terminal" then
      vim.cmd.term()
    end
  else
    vim.api.nvim_win_hide(state.floating.win)
  end
end, {})

vim.keymap.set({ 'n', 't' }, '<space>tt', '<CMD>FloatTerm<CR>')
