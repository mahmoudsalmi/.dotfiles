-- Headless JDTLS integration smoke test. Run with:
-- nvim --headless /absolute/path/to/StockWS.java -c 'luafile ~/.config/nvim/scripts/jdtls-smoke.lua'
local expected_root = vim.env.JDTLS_SMOKE_ROOT
local expected_definition = vim.env.JDTLS_SMOKE_DEFINITION or "/src/colkol/"
local timeout_ms = tonumber(vim.env.JDTLS_SMOKE_TIMEOUT_MS) or 180000
local started = vim.uv.hrtime()
local function elapsed_ms() return (vim.uv.hrtime() - started) / 1e6 end
local function fail(message)
  io.stderr:write("JDTLS_SMOKE_FAIL: " .. message .. "\n")
  vim.cmd("cquit 1")
end

local buf = vim.api.nvim_get_current_buf()
local file = vim.api.nvim_buf_get_name(buf)
local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
local symbol, line_nr, col
for i, line in ipairs(lines) do
  if line:match("^%s*import%s+com%.lsg%.colkol%.helpers%.DateHelper%s*;") then
    symbol = "DateHelper"
    line_nr, col = i - 1, (line:find(symbol, 1, true) or 1) - 1
    break
  end
end
if not symbol then fail("could not find the com.lsg.colkol DateHelper import in " .. file) end

local client
while elapsed_ms() < timeout_ms do
  for _, candidate in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    if candidate.name == "jdtls" then client = candidate; break end
  end
  if client then break end
  vim.wait(200)
end
if not client then fail(("jdtls did not attach within %d ms; see ~/.local/state/nvim/lsp.log"):format(timeout_ms)) end

local root = vim.fs.normalize(client.config.root_dir or "")
local expected = expected_root and vim.fs.normalize(expected_root) or nil
print("JDTLS_SMOKE_CLIENT=" .. client.name)
print("JDTLS_SMOKE_ROOT=" .. root)
print("JDTLS_SMOKE_CMD_JAVA=" .. tostring(client.config.cmd and client.config.cmd[1]))
if expected and root ~= expected then fail(("wrong workspace root: expected %s, got %s"):format(expected, root)) end

local runtimes = (((client.config.settings or {}).java or {}).configuration or {}).runtimes or {}
local runtime_names = {}
for _, runtime in ipairs(runtimes) do runtime_names[#runtime_names + 1] = runtime.name end
table.sort(runtime_names)
print("JDTLS_SMOKE_RUNTIMES=" .. table.concat(runtime_names, ","))
local gradle_home = (((client.config.settings or {}).java or {}).import or {}).gradle
  and client.config.settings.java.import.gradle.java.home
print("JDTLS_SMOKE_GRADLE_JAVA_HOME=" .. tostring(gradle_home))
local has_java8 = false
for _, runtime in ipairs(runtimes) do
  if runtime.name == "JavaSE-1.8" and vim.fn.isdirectory(runtime.path) == 1 then has_java8 = true end
end
if not has_java8 then fail("JavaSE-1.8 runtime is missing or not a directory") end

vim.api.nvim_win_set_cursor(0, { line_nr + 1, col })
local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
local definition
local errors = {}
while elapsed_ms() < timeout_ms do
  local response = client.request_sync("textDocument/definition", params, 3000, buf)
  local result = response and response.result
  local location = result and ((result.uri or result.targetUri) and result or result[1])
  if location then
    local uri = location.uri or location.targetUri
    if uri then
      local path = vim.uri_to_fname(uri)
      if path:find(expected_definition, 1, true) then definition = path end
    end
  end
  errors = vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.ERROR })
  if definition and #errors == 0 then break end
  vim.wait(500)
end
print("JDTLS_SMOKE_DEFINITION=" .. tostring(definition or "NOT_FOUND"))
print("JDTLS_SMOKE_ERROR_DIAGNOSTICS=" .. #errors)
if #errors > 0 then
  for _, diagnostic in ipairs(errors) do
    print(("JDTLS_SMOKE_ERROR=%d:%d %s"):format(diagnostic.lnum + 1, diagnostic.col + 1, diagnostic.message:gsub("\n", " ")))
  end
end
if not definition then fail(("go-to-definition did not resolve into %s within %d ms"):format(expected_definition, timeout_ms)) end
if #errors > 0 then fail("buffer still has compiler error diagnostics") end
print(("JDTLS_SMOKE_PASS elapsed_ms=%.0f file=%s"):format(elapsed_ms(), file))
vim.cmd("qa!")
