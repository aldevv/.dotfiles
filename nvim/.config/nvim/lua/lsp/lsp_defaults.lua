-- this file sets
--  - capabilities
--  - handlers
--  - on_attach
local M = {}
-- ===================
-- LSP FLOATING WINDOW
-- ===================

-- this is so is not overwritten by my colorscheme
vim.cmd([[autocmd ColorScheme * highlight NormalFloat guibg=#1f2335]])
vim.cmd([[autocmd ColorScheme * highlight FloatBorder guifg=white guibg=#1f2335]])

-- local border = {
--       {"🭽", "FloatBorder"},
--       {"▔", "FloatBorder"},
--       {"🭾", "FloatBorder"},
--       {"▕", "FloatBorder"},
--       {"🭿", "FloatBorder"},
--       {"▁", "FloatBorder"},
--       {"🭼", "FloatBorder"},
--       {"▏", "FloatBorder"},
-- }
--
-- local border = { "╔", "═", "╗", "║", "╝", "═", "╚", "║" }
-- local border = "single"
-- local border = "double"
-- local border = "shadow"
local border = "rounded"
-- local border = "solid"

-- ==============
-- HANDLERS
-- ==============
-- LSP settings (for overriding per client)
local handlers = {}
local lsp_handlers = {
    ["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = border }),
    ["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = border }),
    ["textDocument/completion"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = border }),
}
for k, v in pairs(lsp_handlers) do
    handlers[k] = v
end

-- ============
-- DIAGNOSTICS
-- ============
local diagnostic_handlers = {
    ["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
        underline = true,
        virtual_text = {
            spacing = 2,
        },
        signs = true,
        update_in_insert = true,
    }),
}
for k, v in pairs(diagnostic_handlers) do
    handlers[k] = v
end

-- =====
-- LSP
-- =====
-- Add additional capabilities supported by nvim-cmp
--
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").update_capabilities(capabilities)
------------------------------
capabilities.textDocument.completion.completionItem.snippetSupport = true

------------------------------

local on_attach = function(client, buffnr)
    -- these are callbacks that run after the server has loaded
    require("config.keybindings.lsp").load_mappings()
    require("config.automation.lsp").diagnostics_in_loclist()

    -- this disables the lsp's formatting functions
    -- is so null-ls can take charge of formatting
    client.server_capabilities.document_formatting = false
    client.server_capabilities.document_range_formatting = false
end

M.capabilities = capabilities
M.handlers = handlers
M.on_attach = on_attach
return M
