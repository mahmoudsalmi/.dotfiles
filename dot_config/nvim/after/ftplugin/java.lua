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
local function resolve_java(start_dir)
  local sdkman_java = vim.fn.expand("~/.sdkman/candidates/java")

  -- 1. Walk up from the Java buffer looking for .sdkmanrc
  local rc_file = vim.fs.find(".sdkmanrc", {
    path    = start_dir,
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

local filename = vim.api.nvim_buf_get_name(0)
local start_dir = filename ~= "" and vim.fs.dirname(filename) or vim.fn.getcwd()
local project_java_bin, project_java_ver, java_rc = resolve_java(start_dir)

-- JDTLS 1.63 requires Java 21+ to start; choose the newest installed SDKMAN JDK,
-- preferring Temurin when versions tie. Project/Gradle JDK remains .sdkmanrc (or 17).
local sdkman_java = vim.fn.expand("~/.sdkman/candidates/java")
local function version_parts(name)
  local major, minor, patch = name:match("^(%d+)%.(%d+)%.?(%d*)")
  if not major then major = name:match("^(%d+)") end
  return tonumber(major), tonumber(minor) or 0, tonumber(patch) or 0
end
local function newer_jdk(a, b)
  local amajor, aminor, apatch = version_parts(vim.fn.fnamemodify(a, ":t"))
  local bmajor, bminor, bpatch = version_parts(vim.fn.fnamemodify(b, ":t"))
  if amajor ~= bmajor then return amajor > bmajor end
  if aminor ~= bminor then return aminor > bminor end
  if apatch ~= bpatch then return apatch > bpatch end
  return vim.fn.fnamemodify(a, ":t"):match("%-tem$") ~= nil
    and vim.fn.fnamemodify(b, ":t"):match("%-tem$") == nil
end
local function installed_jdks(min_major)
  local dirs = {}
  for _, dir in ipairs(vim.fn.glob(sdkman_java .. "/*", false, true)) do
    local name = vim.fn.fnamemodify(dir, ":t")
    local major = version_parts(name)
    if name ~= "current" and major and major >= min_major and vim.fn.executable(dir .. "/bin/java") == 1 then
      dirs[#dirs + 1] = dir
    end
  end
  table.sort(dirs, newer_jdk)
  return dirs
end
local server_jdks = installed_jdks(21)
local server_java = server_jdks[1] and (server_jdks[1] .. "/bin/java") or project_java_bin
local project_java_home = java_rc and vim.fn.fnamemodify(project_java_bin, ":h:h")
if not project_java_home then
  local fallback = vim.fn.glob(sdkman_java .. "/17.*", false, true)[1]
  project_java_home = fallback and vim.fn.executable(fallback .. "/bin/java") == 1 and fallback or nil
end
vim.notify(
  ("nvim-jdtls: server java=%s; project java=%s [%s]%s"):format(
    server_java,
    project_java_bin,
    project_java_ver,
    java_rc and ("  ← " .. vim.fn.fnamemodify(java_rc, ":~")) or " (Gradle fallback: JDK 17)"
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

-- Prefer the actual Gradle/Maven build root over nested subproject markers; then .git.
-- build.gradle is a fallback for standalone projects that have no wrapper/settings file.
local project_root = vim.fs.root(0, {
  { "settings.gradle.kts", "settings.gradle", "gradlew", "mvnw", "pom.xml" },
  { ".git" },
}) or vim.fs.root(0, { "build.gradle.kts", "build.gradle" }) or start_dir
local project_name = vim.fn.fnamemodify(project_root, ":t") .. "-" .. vim.fn.sha256(project_root):sub(1, 12)
local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspaces/" .. project_name

-- ── Config ───────────────────────────────────────────────────────────────────

local config = {
  -- The command that starts the language server
  cmd = {
    server_java,
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

  -- Root is selected from build markers above, independently of per-module .sdkmanrc files.
  root_dir = project_root,

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
      -- Run Gradle on the project's SDKMAN JDK, independently of the JDTLS server JVM.
      import = { gradle = { enabled = true, wrapper = { enabled = true }, java = { home = project_java_home } } },
      configuration = {
        updateBuildConfiguration = "interactive",
        runtimes = (function()
          local runtimes = {}
          for _, spec in ipairs({
            { "JavaSE-1.8", 8 }, { "JavaSE-11", 11 }, { "JavaSE-17", 17 },
            { "JavaSE-21", 21 }, { "JavaSE-25", 25 },
          }) do
            local candidates = installed_jdks(spec[2])
            for _, dir in ipairs(candidates) do
              if version_parts(vim.fn.fnamemodify(dir, ":t")) == spec[2] then
                runtimes[#runtimes + 1] = { name = spec[1], path = dir }
                break
              end
            end
          end
          return runtimes
        end)(),
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
