-- lua/config/ts_lsp.lua
-- TypeScript / JavaScript LSP: auto-detect Deno vs Node, resolve the right
-- node binary via fnm. Called from after/ftplugin/{typescript,typescriptreact,
-- javascript,javascriptreact}.lua.
--
-- Setup:
--   Deno  → ships with `deno lsp`; no extra install needed.
--   Node  → :MasonInstall typescript-language-server

local M = {}

-- ── fnm ──────────────────────────────────────────────────────────────────────

--- Locate fnm's data directory.
--- Checks FNM_DIR env var first (set by `fnm env`), then common OS paths.
--- On macOS fnm defaults to ~/Library/Application Support/fnm.
local function find_fnm_dir()
  local candidates = {
    os.getenv("FNM_DIR"),
    vim.fn.expand("~/Library/Application Support/fnm"), -- macOS
    vim.fn.expand("~/.local/share/fnm"),                -- Linux / XDG
    vim.fn.expand("~/.fnm"),
  }
  for _, d in ipairs(candidates) do
    if d and d ~= "" and vim.fn.isdirectory(d) == 1 then
      return d
    end
  end
end

--- Parse a .node-version or .nvmrc file.
--- Returns a "vX.Y.Z" string (normalised with leading "v"), or nil.
local function parse_node_version_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local raw = f:read("*l")
  f:close()
  if not raw then return nil end
  raw = raw:match("^%s*(.-)%s*$")           -- trim whitespace
  if not raw:match("^v") then raw = "v" .. raw end
  return raw ~= "v" and raw or nil
end

--- Resolve Node from fnm, the project's active mise selection, or system PATH.
--- Returns (absolute_bin_path, version_label), or (nil, nil) if unavailable.
local function resolve_node(version, fnm, cwd)
  if version and fnm then
    local bin = fnm .. "/node-versions/" .. version .. "/installation/bin/node"
    if vim.fn.executable(bin) == 1 then
      return bin, version .. " (fnm)"
    end
    vim.notify(
      ("nvim ts: .node-version wants %s but it is not installed in fnm. Falling back."):format(version),
      vim.log.levels.WARN
    )
  end

  -- fnm "default" alias symlink
  if fnm then
    local default = fnm .. "/aliases/default/bin/node"
    if vim.fn.executable(default) == 1 then
      return default, "default (fnm)"
    end
  end

  -- Resolve the active mise selection to its real binary so the Mason server
  -- wrapper cannot accidentally re-enter an unset or differently selected shim.
  local mise = vim.fn.exepath("mise")
  if mise ~= "" then
    local result = vim.system({ mise, "which", "node" }, { cwd = cwd, text = true }):wait()
    local bin = vim.trim(result.stdout or "")
    if result.code == 0 and bin ~= "" and vim.fn.executable(bin) == 1 then
      local version_result = vim.system({ bin, "--version" }, { cwd = cwd, text = true }):wait()
      local version_out = vim.trim(version_result.stdout or "")
      return bin, version_out ~= "" and (version_out .. " (mise)") or "mise"
    end
  end

  -- Accept a system Node only if it can actually run. This rejects an unset
  -- mise shim, which is executable but exits with an error when invoked.
  local bin = vim.fn.exepath("node")
  if bin ~= "" then
    local result = vim.system({ bin, "--version" }, { cwd = cwd, text = true }):wait()
    local version_out = vim.trim(result.stdout or "")
    if result.code == 0 then
      return bin, version_out ~= "" and (version_out .. " (PATH)") or "system PATH"
    end
  end

  return nil, nil
end

-- ── Detection ─────────────────────────────────────────────────────────────────

--- Detect the JS/TS runtime for the current working directory.
---
--- Returns a table:
---   { type = "deno" | "node" | "unknown",
---     root = "/abs/project/root" }
---
--- For type == "node", additional fields:
---   { node_bin     = "/abs/path/to/node",
---     node_version = "v24.11.1",
---     node_bin_dir = "/abs/path/to/node/../bin",  ← prepend to PATH
---     version_file = "/abs/path/.node-version" | nil }
function M.detect(cwd)
  if not cwd or cwd == "" then
    local filename = vim.api.nvim_buf_get_name(0)
    cwd = filename ~= "" and vim.fs.dirname(filename) or vim.fn.getcwd()
  end

  -- ── Deno: wins if deno.json / deno.jsonc is anywhere in the tree ───────────
  local deno_conf = vim.fs.find({ "deno.json", "deno.jsonc" }, {
    path = cwd, upward = true, type = "file", limit = 1,
  })[1]
  if deno_conf then
    return {
      type = "deno",
      root = vim.fs.dirname(deno_conf),
    }
  end

  -- ── Node: package.json or tsconfig.json ────────────────────────────────────
  local node_conf = vim.fs.find({ "package.json", "tsconfig.json" }, {
    path = cwd, upward = true, type = "file", limit = 1,
  })[1]
  if node_conf then
    local root = vim.fs.dirname(node_conf)

    -- Walk up from root for the version pin file
    local ver_file = vim.fs.find({ ".node-version", ".nvmrc" }, {
      path = root, upward = true, type = "file", limit = 1,
    })[1]

    local fnm = find_fnm_dir()
    local node_bin, node_version

    if ver_file then
      local v = parse_node_version_file(ver_file)
      if v then
        node_bin, node_version = resolve_node(v, fnm, root)
      end
    end

    -- No usable .node-version (or no fnm): use the active mise selection,
    -- then a working system Node if available.
    if not node_bin then
      node_bin, node_version = resolve_node(nil, fnm, root)
    end

    return {
      type         = "node",
      root         = root,
      node_bin     = node_bin,
      node_version = node_version,
      node_bin_dir = node_bin and vim.fs.dirname(node_bin) or nil,
      version_file = ver_file,
    }
  end

  local node_bin, node_version = resolve_node(nil, find_fnm_dir(), cwd)
  return {
    type = "unknown",
    root = cwd,
    node_bin = node_bin,
    node_version = node_version,
    node_bin_dir = node_bin and vim.fs.dirname(node_bin) or nil,
  }
end

-- ── LSP startup ───────────────────────────────────────────────────────────────

--- on_attach shared by both denols and ts_ls.
local function on_attach(_, bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
  end
  -- Override native gd / gD / gi (Vim built-ins that ignore the LSP)
  map("n", "gd", vim.lsp.buf.definition,      "Go to Definition")
  map("n", "gD", vim.lsp.buf.declaration,     "Go to Declaration")
  map("n", "gi", vim.lsp.buf.implementation,  "Go to Implementation")
  map("n", "gy", vim.lsp.buf.type_definition, "Go to Type Definition")
end

--- Entry point called from each ftplugin file.
function M.start()
  local rt   = M.detect()
  local caps = require("blink.cmp").get_lsp_capabilities()

  -- ── Deno ───────────────────────────────────────────────────────────────────
  if rt.type == "deno" then
    vim.notify(
      ("nvim ts [deno]  root: %s"):format(vim.fn.fnamemodify(rt.root, ":~")),
      vim.log.levels.INFO
    )
    vim.lsp.start({
      name         = "denols",
      cmd          = { "deno", "lsp" },
      root_dir     = rt.root,
      capabilities = caps,
      on_attach    = on_attach,
      init_options = {
        lint     = true,
        unstable = false,
        suggest  = {
          imports = {
            hosts = {
              ["https://deno.land"] = true,
              ["https://jsr.io"]    = true,
              ["https://esm.sh"]    = true,
            },
          },
        },
      },
    })

  -- ── Node ───────────────────────────────────────────────────────────────────
  elseif rt.type == "node" then
    if not rt.node_bin then
      vim.notify(
        "nvim ts [node]: no working Node.js runtime found. Select/install one with mise (for example, `mise use node@lts` in the project), or configure fnm.",
        vim.log.levels.WARN
      )
      return
    end

    local ts_bin = vim.fn.stdpath("data") .. "/mason/bin/typescript-language-server"
    if vim.fn.executable(ts_bin) ~= 1 then
      vim.notify(
        "nvim ts [node]: typescript-language-server not found.\nRun :MasonInstall typescript-language-server",
        vim.log.levels.WARN
      )
      return
    end

    vim.notify(
      ("nvim ts [node]  %s%s"):format(
        rt.node_version,
        rt.version_file and ("  ← " .. vim.fn.fnamemodify(rt.version_file, ":~")) or ""
      ),
      vim.log.levels.INFO
    )

    -- Prepend fnm node's bin dir to PATH so the mason wrapper uses the right node
    local path_env = rt.node_bin_dir .. ":" .. (os.getenv("PATH") or "")

    vim.lsp.start({
      name         = "ts_ls",
      cmd          = { ts_bin, "--stdio" },
      cmd_env      = { PATH = path_env },
      root_dir     = rt.root,
      capabilities = caps,
      on_attach    = on_attach,
      settings = {
        typescript = {
          inlayHints = {
            includeInlayParameterNameHints                        = "literals",
            includeInlayParameterNameHintsWhenArgumentMatchesName = false,
            includeInlayFunctionParameterTypeHints                = true,
            includeInlayVariableTypeHints                         = false,
            includeInlayPropertyDeclarationTypeHints              = true,
            includeInlayFunctionLikeReturnTypeHints               = true,
            includeInlayEnumMemberValueHints                      = true,
          },
        },
        javascript = {
          inlayHints = {
            includeInlayParameterNameHints                        = "literals",
            includeInlayParameterNameHintsWhenArgumentMatchesName = false,
            includeInlayFunctionParameterTypeHints                = true,
            includeInlayVariableTypeHints                         = false,
            includeInlayPropertyDeclarationTypeHints              = true,
            includeInlayFunctionLikeReturnTypeHints               = true,
            includeInlayEnumMemberValueHints                      = true,
          },
        },
      },
    })

  -- ── Unknown (no package.json, tsconfig.json, or deno.json found) ───────────
  else
    local ts_bin = vim.fn.stdpath("data") .. "/mason/bin/typescript-language-server"
    if vim.fn.executable(ts_bin) == 1 and rt.node_bin then
      local path_env = rt.node_bin_dir .. ":" .. (os.getenv("PATH") or "")
      vim.lsp.start({
        name         = "ts_ls",
        cmd          = { ts_bin, "--stdio" },
        cmd_env      = { PATH = path_env },
        root_dir     = rt.root,
        capabilities = caps,
        on_attach    = on_attach,
      })
    end
  end
end

return M
