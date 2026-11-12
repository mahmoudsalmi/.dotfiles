local function preview_file_link()
  local buf = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
  local target, image_link

  -- Recognize a Markdown link/image when the cursor is anywhere on it.
  local from = 1
  while true do
    local first, last, link = line:find("!?%[[^%]]*%]%(([^%)]+)%)", from)
    if not first then break end
    if col + 1 >= first and col + 1 <= last then
      target = link:match("^%s*<([^>]+)>") or link:match("^%s*([^%s]+)")
      image_link = line:sub(first, first) == "!"
      break
    end
    from = last + 1
  end

  -- Also allow a bare file path under the cursor.
  target = target or vim.fn.expand("<cfile>")
  target = target:gsub("^['\"]", ""):gsub("['\"]$", "")
  target = target:match("^[^#?]+") or target

  if target == "" or target:match("^%w+://") then
    vim.notify("No local file link under cursor", vim.log.levels.INFO)
    return
  end

  target = vim.fn.expand(target)
  local path = vim.fs.is_absolute(target) and target
      or vim.fs.joinpath(vim.fs.dirname(vim.api.nvim_buf_get_name(buf)), target)
  if vim.fn.filereadable(path) == 0 then
    path = vim.fs.is_absolute(target) and target or vim.fs.joinpath(vim.fn.getcwd(), target)
  end
  if vim.fn.filereadable(path) == 0 then
    vim.notify("File not found: " .. target, vim.log.levels.WARN)
    return
  end

  local ext = vim.fn.fnamemodify(path, ":e"):lower()
  local image = vim.tbl_contains({ "png", "jpg", "jpeg", "gif", "webp", "bmp", "tif", "tiff", "avif", "heic", "pdf" }, ext)
  if image then
    if image_link then
      Snacks.image.hover()
    else
      vim.notify("For image hover, use a Markdown image link: ![alt](path)", vim.log.levels.INFO)
    end
    return
  end

  local lines = vim.fn.readfile(path, "", 31)
  if #lines == 0 then lines = { "(empty file)" } end
  if #lines > 30 then
    lines = { unpack(lines, 1, 30) }
    table.insert(lines, "… (preview truncated)")
  end
  local ft = vim.filetype.match({ filename = path }) or "text"
  vim.lsp.util.open_floating_preview(lines, ft, {
    border = "rounded",
    max_width = 100,
    max_height = 30,
    focusable = false,
    title = vim.fn.fnamemodify(path, ":t"),
  })
end

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    keys = {
      { "<leader>p", preview_file_link, desc = "Preview file link" },
    },
    opts = {
      image = {
        enabled = true,
        doc = { enabled = true, inline = false, float = true },
      },
    },
  },
}
