-- conform.nvim: formatter dispatcher (replaces unmaintained none-ls).
-- Per-filetype formatter mapping lives in lua/config/plugins/lsp/formatters.lua.

return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo", "ConformFormat" },
  config = function()
    require("config.plugins.lsp.formatters")
  end,
}
