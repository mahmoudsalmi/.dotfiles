-- SonarLint diagnostics for Java and JavaScript/TypeScript.
-- Install the language server with :MasonInstall sonarlint-language-server.
return {
  {
    "schrieveslaach/sonarlint.nvim",
    url = "https://gitlab.com/schrieveslaach/sonarlint.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "lewis6991/gitsigns.nvim" },
    config = function()
      local analyzer_dir = vim.fn.stdpath("data") .. "/mason/share/sonarlint-analyzers"

      require("sonarlint").setup({
        server = {
          cmd = {
            "sonarlint-language-server",
            "-stdio",
            "-analyzers",
            analyzer_dir .. "/sonarjava.jar",
            analyzer_dir .. "/sonarjs.jar",
          },
        },
        filetypes = {
          "java",
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
        },
      })
    end,
  },
}
