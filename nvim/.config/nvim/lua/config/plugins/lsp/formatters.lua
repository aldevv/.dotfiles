-- conform.nvim: formatter dispatcher (replaces unmaintained none-ls.nvim).
-- nvim-lint handles diagnostics (vint, luacheck); see lint.lua sibling file.

local ok, conform = pcall(require, "conform")
if not ok then
  vim.notify("conform.nvim not loaded", vim.log.levels.WARN)
  return
end

conform.setup({
  formatters_by_ft = {
    lua = { "stylua" },
    sh = { "shfmt" },
    bash = { "shfmt" },
    zsh = { "shfmt" },
    sql = { "sql_formatter" },
    c = { "clang-format" },
    cpp = { "clang-format" },
    objc = { "clang-format" },
    objcpp = { "clang-format" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    svelte = { "prettier" },
    vue = { "prettier" },
    css = { "prettier" },
    scss = { "prettier" },
    html = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    yaml = { "prettier" },
    markdown = { "prettier" },
    -- python is owned by ruff (LSP server); skip here
    -- go is owned by gopls; skip here
    -- rust is owned by rustaceanvim; skip here
  },
  formatters = {
    shfmt = {
      prepend_args = { "-i", "2", "-bn", "-ci" },
    },
    sql_formatter = {
      prepend_args = { "-l", "snowflake" },
    },
  },
  -- format-on-save is owned by the autocmd in lua/config/automation/init.lua
  -- (it calls vim.lsp.buf.format which delegates to conform via
  -- the formatexpr conform sets up). No format_after_save here.
})

-- conform integrates with vim.lsp.buf.format by setting `formatexpr` and
-- providing a `format()` API. The format-on-save autocmd in automation/init.lua
-- calls vim.lsp.buf.format which falls back to conform for non-LSP filetypes.
vim.api.nvim_create_user_command("ConformFormat", function(args)
  local range = nil
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = {
      start = { args.line1, 0 },
      ["end"] = { args.line2, end_line:len() },
    }
  end
  conform.format({ async = true, lsp_format = "fallback", range = range })
end, { range = true })
