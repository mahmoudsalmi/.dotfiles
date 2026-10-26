return {
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on lua files
        opts = {
          library = {
            -- See the configuration section for more details
            -- Load luvit types when the `vim.uv` word is found
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          },
        },
      },
      'saghen/blink.cmp',
      'github/copilot.vim',
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
      local capabilities = require('blink.cmp').get_lsp_capabilities()

      -- ── Diagnostic display ──────────────────────────────────────────────────
      vim.diagnostic.config({
        underline        = true,
        virtual_text     = { prefix = "●", source = "if_many" },
        signs            = true,
        update_in_insert = false,
        severity_sort    = true,
        float            = {
          border = "rounded",
          source = true, -- show "eslint", "jdtls", etc. in the float
        },
      })

      -- Neovim 0.11+ native LSP config API: share completion capabilities
      -- across servers, then keep server-specific overrides alongside them.
      vim.lsp.config("*", { capabilities = capabilities })
      vim.lsp.config("lua_ls", {})
      vim.lsp.config("bashls", {
        filetypes = { "bash", "sh", "zsh" },
      })
      vim.lsp.config("clangd", {
        cmd = { "clangd", "--background-index", "--clang-tidy" },
      })

      vim.lsp.enable("clangd")

      require 'mason'.setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        }
      })
      require 'mason-lspconfig'.setup({
        ensure_installed = {},
        -- These servers are started manually from after/ftplugin/ with
        -- runtime detection (fnm, sdkman) and must not be auto-enabled:
        automatic_enable = { exclude = { "denols", "ts_ls", "jdtls" } },
      })


      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then return end

          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, silent = true, desc = desc })
          end

          -- ── Diagnostic navigation ─────────────────────────────────────────
          map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next Diagnostic")
          map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Prev Diagnostic")
          map("n", "]e",
            function() vim.diagnostic.jump({ count = 1, float = true, severity = vim.diagnostic.severity.ERROR }) end,
            "Next Error")
          map("n", "[e",
            function() vim.diagnostic.jump({ count = -1, float = true, severity = vim.diagnostic.severity.ERROR }) end,
            "Prev Error")
          map("n", "]w",
            function() vim.diagnostic.jump({ count = 1, float = true, severity = vim.diagnostic.severity.WARN }) end,
            "Next Warning")
          map("n", "[w",
            function() vim.diagnostic.jump({ count = -1, float = true, severity = vim.diagnostic.severity.WARN }) end,
            "Prev Warning")

          -- ── Diagnostic display ────────────────────────────────────────────
          map("n", "<leader>cd", vim.diagnostic.open_float, "Diagnostic: float")
          map("n", "<leader>cq", vim.diagnostic.setloclist, "Diagnostic: location list")

          -- ── LSP actions and navigation ─────────────────────────────────────
          map("n", "<leader>ca", vim.lsp.buf.code_action,    "Code Action")
          map("v", "<leader>ca", vim.lsp.buf.code_action,    "Code Action")
          map("n", "<leader>cr", vim.lsp.buf.rename,         "Rename Symbol")
          map("n", "<leader>ch", vim.lsp.buf.hover,          "Hover Docs")
          map("n", "<leader>cs", vim.lsp.buf.signature_help, "Signature Help")
          map("n", "gd", vim.lsp.buf.definition,      "Go to Definition")
          map("n", "gD", vim.lsp.buf.declaration,     "Go to Declaration")
          map("n", "gi", vim.lsp.buf.implementation,  "Go to Implementation")
          map("n", "gy", vim.lsp.buf.type_definition, "Go to Type Definition")
          map("n", "gr", vim.lsp.buf.references,      "Go to References")

          if client.name == "clangd" then
            map("n", "<leader>cH", "<cmd>LspClangdSwitchSourceHeader<cr>", "C: Switch Source/Header")
          end

          -- ── Format ───────────────────────────────────────────────────────
          -- <leader>cf is handled globally by conform.nvim (format.lua)
          -- This is a fallback for LSPs not covered by conform
          if client:supports_method('textDocument/formatting') then
            map("n", "<leader>cF",
              function() vim.lsp.buf.format({ bufnr = args.buf, id = client.id }) end,
              "Format (LSP direct)"
            )
          end
        end,
      })
    end,
  }
}
