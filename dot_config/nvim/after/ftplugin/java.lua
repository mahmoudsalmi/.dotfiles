-- after/ftplugin/java.lua
-- Runs automatically when a Java buffer is opened.
-- Requires: :MasonInstall jdtls

local ok, jdtls = pcall(require, "jdtls")
if not ok then return end

-- ── Java executable (SDKMAN-aware) ───────────────────────────────────────────

--- Read a .sdkmanrc file and return a table of { key = version } pairs.
--- Returns nil if the file cannot be opened.
local function parse_sdkmanrc(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local entries = {}
  for line in f:lines() do
    -- skip blank lines and comments
    local key, val = line:match("^%s*([%w_]+)%s*=%s*([^%s#]+)")
    if key then entries[key] = val end
  end
  f:close()
  return entries
end

--- Resolve the java binary to use for JDTLS:
---   1. .sdkmanrc in the project tree  → ~/.sdkman/candidates/java/<ver>/bin/java
---   2. ~/.sdkman/candidates/java/current/bin/java
---   3. bare "java" on PATH (system default)
---
--- Also returns the resolved version string (or nil) so it can be logged.
local function resolve_java()
  local sdkman_java = vim.fn.expand("~/.sdkman/candidates/java")

  -- 1. Walk up from cwd looking for .sdkmanrc
  local rc_file = vim.fs.find(".sdkmanrc", {
    path    = vim.fn.getcwd(),
    upward  = true,
    type    = "file",
    limit   = 1,
  })[1]

  if rc_file then
    local entries = parse_sdkmanrc(rc_file)
    local version = entries and entries["java"]
    if version then
      local bin = sdkman_java .. "/" .. version .. "/bin/java"
      if vim.fn.executable(bin) == 1 then
        return bin, version, rc_file
      end
      vim.notify(
        ("nvim-jdtls: .sdkmanrc wants java=%s but %s is not executable.\nFalling back."):format(version, bin),
        vim.log.levels.WARN
      )
    end
  end

  -- 2. SDKMAN "current" symlink
  local current = sdkman_java .. "/current/bin/java"
  if vim.fn.executable(current) == 1 then
    return current, "current (sdkman)", nil
  end

  -- 3. Whatever is on PATH
  return "java", "system PATH", nil
end

local java_bin, java_ver, java_rc = resolve_java()
vim.notify(
  ("nvim-jdtls: using java=%s  [%s]%s"):format(
    java_bin,
    java_ver,
    java_rc and ("  ← " .. vim.fn.fnamemodify(java_rc, ":~")) or ""
  ),
  vim.log.levels.INFO
)

-- ── Paths ────────────────────────────────────────────────────────────────────

local mason_jdtls = vim.fn.stdpath("data") .. "/mason/packages/jdtls"

-- Pick the right JDTLS native config directory for the current OS
local os_config = "config_linux"
if vim.fn.has("mac") == 1 then
  os_config = "config_mac"
elseif vim.fn.has("win32") == 1 then
  os_config = "config_win"
end

-- The launcher JAR (version-agnostic glob)
local launcher_jar = vim.fn.glob(mason_jdtls .. "/plugins/org.eclipse.equinox.launcher_*.jar")
if launcher_jar == "" then
  vim.notify("nvim-jdtls: JDTLS not found. Run :MasonInstall jdtls", vim.log.levels.WARN)
  return
end

-- Unique workspace dir per project root (avoids cross-project contamination)
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspaces/" .. project_name

-- ── Config ───────────────────────────────────────────────────────────────────

local config = {
  -- The command that starts the language server
  cmd = {
    java_bin,
    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=true",
    "-Dlog.level=ALL",
    "-Xmx1g",
    "--add-modules=ALL-SYSTEM",
    "--add-opens", "java.base/java.util=ALL-UNNAMED",
    "--add-opens", "java.base/java.lang=ALL-UNNAMED",
    "-jar", launcher_jar,
    "-configuration", mason_jdtls .. "/" .. os_config,
    "-data", workspace_dir,
  },

  -- Root detection: walk up from the current file to find the project root.
  -- .sdkmanrc is included so monorepos with per-module SDKMANrc files are handled.
  root_dir = vim.fs.root(0, {
    ".git",
    ".sdkmanrc",
    "mvnw", "gradlew",
    "pom.xml",
    "build.gradle", "build.gradle.kts",
    "settings.gradle", "settings.gradle.kts",
  }),

  -- Wire in blink.cmp capabilities
  capabilities = require("blink.cmp").get_lsp_capabilities(),

  -- ── LSP settings sent to JDTLS ─────────────────────────────────────────────
  settings = {
    java = {
      eclipse = { downloadSources = true },
      maven   = { downloadSources = true },
      format  = { enabled = true },
      signatureHelp = { enabled = true },
      implementationsCodeLens = { enabled = true },
      referencesCodeLens      = { enabled = false },
      configuration = {
        updateBuildConfiguration = "interactive",
        -- Uncomment and adjust to tell JDTLS about your installed JDKs:
        -- runtimes = {
        --   { name = "JavaSE-21", path = "/path/to/jdk-21" },
        --   { name = "JavaSE-17", path = "/path/to/jdk-17" },
        -- },
      },
      completion = {
        favoriteStaticMembers = {
          "org.junit.jupiter.api.Assertions.*",
          "org.mockito.Mockito.*",
          "java.util.Objects.requireNonNull",
          "java.util.Objects.requireNonNullElse",
        },
        filteredTypes = {
          "com.sun.*",
          "io.micrometer.shaded.*",
          "java.awt.*",
          "jdk.*",
          "sun.*",
        },
      },
    },
  },

  -- ── on_attach: Java-specific keymaps ───────────────────────────────────────
  on_attach = function(_, bufnr)
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
    end

    -- LSP navigation (override Neovim's native gd / gD which never use the LSP)
    map("n", "gd", vim.lsp.buf.definition,      "Go to Definition")
    map("n", "gD", vim.lsp.buf.declaration,     "Go to Declaration")
    map("n", "gi", vim.lsp.buf.implementation,  "Go to Implementation")
    map("n", "gy", vim.lsp.buf.type_definition, "Go to Type Definition")

    -- Refactoring
    map("n", "<leader>ji", jdtls.organize_imports,                         "Java: Organize Imports")
    map("n", "<leader>jv", jdtls.extract_variable,                         "Java: Extract Variable")
    map("v", "<leader>jv", function() jdtls.extract_variable(true) end,    "Java: Extract Variable")
    map("n", "<leader>jc", jdtls.extract_constant,                         "Java: Extract Constant")
    map("v", "<leader>jc", function() jdtls.extract_constant(true) end,    "Java: Extract Constant")
    map("v", "<leader>jm", function() jdtls.extract_method(true) end,      "Java: Extract Method")

    -- Build / test helpers (requires nvim-dap + java-test bundle for full support)
    map("n", "<leader>jt", jdtls.test_nearest_method,                      "Java: Test Nearest Method")
    map("n", "<leader>jT", jdtls.test_class,                               "Java: Test Class")
  end,
}

-- Start (or re-attach to) the JDTLS server for this buffer
jdtls.start_or_attach(config)
