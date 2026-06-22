-- nvim-lint: per-filetype diagnostics (replaces none-ls diagnostic sources).

local ok, lint = pcall(require, "lint")
if not ok then
  vim.notify("nvim-lint not loaded", vim.log.levels.WARN)
  return
end

lint.linters_by_ft = {
  vim = { "vint" },
  lua = { "luacheck" },
  -- python is linted by ruff (LSP)
  -- sh handled by bashls; shellcheck not enabled to avoid noise
}

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
  group = vim.api.nvim_create_augroup("nvim_lint_try", { clear = true }),
  callback = function()
    -- bigfile-aware: skip lint on huge files (vim.b.bigfile is set in
    -- lua/config/automation/init.lua).
    if vim.b.bigfile then return end
    lint.try_lint()
  end,
})
