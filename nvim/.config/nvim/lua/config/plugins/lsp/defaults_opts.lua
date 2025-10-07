local M = {}

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

local capabilities = require("blink.cmp").get_lsp_capabilities()
-- local capabilities = require("cmp_nvim_lsp").default_capabilities()

capabilities.textDocument.completion.completionItem.snippetSupport = true
-- Fix position_encoding warning in Neovim 0.11+
capabilities.general = capabilities.general or {}
capabilities.general.positionEncodings = { 'utf-16', 'utf-8' }
-- NOTE: this is for ufo when using the lsp provider
-- capabilities.textDocument.foldingRange = {
--   dynamicRegistration = false,
--   lineFoldingOnly = true
-- }

local on_attach = function(client, bufnr)
  require("keybindings.langs").load_mappings(client.name)
  require("keybindings.dap").load_mappings(client.name)
  require("keybindings.lsp").load_mappings()
end

M.capabilities = capabilities
M.handlers = handlers
M.on_attach = on_attach
return M
