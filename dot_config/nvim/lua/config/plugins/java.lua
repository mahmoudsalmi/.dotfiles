return {
  {
    "mfussenegger/nvim-jdtls",
    ft = "java", -- only load for Java files
    -- JDTLS itself is installed via Mason: :MasonInstall jdtls
    -- All configuration lives in after/ftplugin/java.lua
  },
}
