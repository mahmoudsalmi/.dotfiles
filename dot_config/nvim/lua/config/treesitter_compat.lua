-- nvim-treesitter's legacy query predicates expect one TSNode per capture.
-- Neovim 0.12 passes a list of nodes, so unwrap single-capture values before
-- the affected directives read their text.
local query = vim.treesitter.query
local force = { force = true }

local function captured_node(match, capture)
  local nodes = match[capture]
  if type(nodes) == "table" then
    return nodes[1]
  end
  return nodes
end

local function info_string_language(info)
  local aliases = {
    ex = "elixir",
    pl = "perl",
    sh = "bash",
    uxn = "uxntal",
    ts = "typescript",
  }
  return vim.filetype.match({ filename = "a." .. info }) or aliases[info] or info
end

query.add_directive("downcase!", function(match, _, bufnr, pred, metadata)
  local id = pred[2]
  local node = captured_node(match, id)
  if not node then
    return
  end

  local text = vim.treesitter.get_node_text(node, bufnr, { metadata = metadata[id] }) or ""
  metadata[id] = metadata[id] or {}
  metadata[id].text = text:lower()
end, force)

query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
  local node = captured_node(match, pred[2])
  if node then
    local info = vim.treesitter.get_node_text(node, bufnr):lower()
    metadata["injection.language"] = info_string_language(info)
  end
end, force)

query.add_directive("set-lang-from-mimetype!", function(match, _, bufnr, pred, metadata)
  local node = captured_node(match, pred[2])
  if not node then
    return
  end

  local value = vim.treesitter.get_node_text(node, bufnr)
  local languages = {
    importmap = "json",
    module = "javascript",
    ["application/ecmascript"] = "javascript",
    ["text/ecmascript"] = "javascript",
  }
  metadata["injection.language"] = languages[value] or value:match("([^/]+)$")
end, force)
