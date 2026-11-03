return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local has_compiler = vim.fn.executable("cc") == 1
        or vim.fn.executable("gcc") == 1
        or vim.fn.executable("clang") == 1
      local parsers = {
        "c",
        "lua",
        "vim",
        "vimdoc", "query",
        "markdown",
        "markdown_inline",
        "java",
        "kotlin",
        -- Fenced code blocks in Markdown are highlighted by the parser of
        -- their language (```bash, ```json...); install those you write.
        "bash",
        "json",
        "yaml",
        "toml",
        "python",
        "javascript",
        "typescript",
        "html",
        "css",
        "go",
        "rust",
        "sql",
        "dockerfile",
        "diff",
        "regex",
      }

      -- The current nvim-treesitter API no longer has the legacy `configs`
      -- module. Install parsers explicitly, and enable Neovim's native
      -- Tree-sitter highlighting for reasonably sized buffers.
      require('nvim-treesitter').setup()

      local function install_parsers_if_ready()
        if has_compiler and vim.fn.executable('tree-sitter') == 1 then
          require('nvim-treesitter').install(parsers)
        end
      end

      -- Mason may install tree-sitter-cli asynchronously after this plugin's
      -- startup config has run, so retry parser installation when it finishes.
      install_parsers_if_ready()
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MasonToolsUpdateCompleted',
        group = vim.api.nvim_create_augroup('config-treesitter-install', { clear = true }),
        callback = install_parsers_if_ready,
      })

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('config-treesitter-highlight', { clear = true }),
        callback = function(args)
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall((vim.uv or vim.loop).fs_stat, vim.api.nvim_buf_get_name(args.buf))
          if ok and stats and stats.size <= max_filesize then
            pcall(vim.treesitter.start, args.buf)
          end
        end,
      })
    end
  }
}
