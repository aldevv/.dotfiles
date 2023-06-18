local M = {}
-- this is so is not overwritten by my colorscheme
vim.cmd([[autocmd ColorScheme * highlight NormalFloat guibg=#1f2335]])
vim.cmd([[autocmd ColorScheme * highlight FloatBorder guifg=white guibg=#1f2335]])

local border = "rounded"
-- local border = "solid"

-- LSP settings (for overriding per client)
local handlers = {}
local lsp_handlers = {
  ["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = border }),
  ["textDocument/signatureHelp"] = vim.lsp.with(
    vim.lsp.handlers.signature_help,
    { border = border, focusable = false }
  ),
  ["textDocument/completion"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = border }),
}
for k, v in pairs(lsp_handlers) do
  handlers[k] = v
end

local capabilities = require("cmp_nvim_lsp").default_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
-- NOTE: this is for ufo when using the lsp provider
-- capabilities.textDocument.foldingRange = {
--   dynamicRegistration = false,
--   lineFoldingOnly = true
-- }

local on_attach = function(client, bufnr)
  require("config.keybindings.lsp").load_mappings(client.name)
  require("config.automation.lsp").diagnostics_in_loclist()
  require("config.keybindings.dap").load_mappings(client.name)
  -- make which-key load the new mappings added here
  require("which-key").register({})
end

M.capabilities = capabilities
M.handlers = handlers
M.on_attach = on_attach
return M
