-- nvim-lint: per-filetype linters (replaces none-ls diagnostic sources).
-- Linter mapping + try_lint autocmd live in lua/config/plugins/lsp/lint.lua.

return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("config.plugins.lsp.lint")
  end,
}
