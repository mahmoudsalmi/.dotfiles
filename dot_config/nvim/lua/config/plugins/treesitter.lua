return {
  {
    "nvim-treesitter/nvim-treesitter",
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

      require 'nvim-treesitter.configs'.setup {
        -- Install parsers when a compiler is available. Bootstrap installs the
        -- platform build toolchain; this keeps existing minimal systems usable.
        ensure_installed = has_compiler and parsers or {},
        auto_install = false,
        highlight = {
          enable = true,
          disable = function(name, buf)
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
              return true
            end
          end,
          additional_vim_regex_highlighting = false,
        },
      }
    end
  }
}
