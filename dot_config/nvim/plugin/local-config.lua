local project_config = vim.fn.getcwd() .. "/.nvimrc"
if vim.fn.filereadable(project_config) == 1 then
  vim.cmd("source " .. project_config)
end


local project_config_lua = vim.fn.getcwd() .. "/.nvimrc.lua"
if vim.fn.filereadable(project_config_lua) == 1 then
  dofile(project_config_lua)
end
