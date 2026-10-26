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

--- Resolve the node binary for `version` inside fnm's node-versions tree.
--- Falls back to fnm's "default" alias, then bare "node" on PATH.
--- Returns (bin_path, version_label).
local function resolve_node(version, fnm)
  if fnm then
    local bin = fnm .. "/node-versions/" .. version .. "/installation/bin/node"
    if vim.fn.executable(bin) == 1 then
      return bin, version
    end
    vim.notify(
      ("nvim ts: .node-version wants %s but not found in fnm. Falling back."):format(version),
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

  return "node", "system PATH"
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
  cwd = cwd or vim.fn.getcwd()

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
        node_bin, node_version = resolve_node(v, fnm)
      end
    end

    -- No version file (or parse failed): fall back to fnm default / PATH
    if not node_bin then
      if fnm then
        local default = fnm .. "/aliases/default/bin/node"
        node_bin     = vim.fn.executable(default) == 1 and default or "node"
        node_version = "default (fnm)"
      else
        node_bin, node_version = "node", "system PATH"
      end
    end

    return {
      type         = "node",
      root         = root,
      node_bin     = node_bin,
      node_version = node_version,
      node_bin_dir = vim.fs.dirname(node_bin),
      version_file = ver_file,
    }
  end

  return { type = "unknown" }
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
    if vim.fn.executable(ts_bin) == 1 then
      vim.lsp.start({
        name         = "ts_ls",
        cmd          = { ts_bin, "--stdio" },
        root_dir     = vim.fn.getcwd(),
        capabilities = caps,
        on_attach    = on_attach,
      })
    end
  end
end

return M
