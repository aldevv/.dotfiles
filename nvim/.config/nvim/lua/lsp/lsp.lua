-- -----------
-- LSP
-- -----------
local servers = {
    "bashls",
    "pyright",
    "clangd",
    "html",
    "cssls",
    "tsserver",
    "svelte",
    "sumneko_lua",
    "vimls",
    "gopls",
    "dockerls",
    "jsonls",
    "rust_analyzer",
    "volar",
    "sqls",
    "hls",
    "emmet_ls",
}

require("mason").setup()
require("mason-lspconfig").setup({
    automatic_installation = true,
    ensure_installed = servers,
})

local lsp_defaults = require("lsp.lsp_defaults")
local lang_opts = require("lsp.lang_opts")

local opts = {
    capabilities = lsp_defaults.capabilities,
    handlers = lsp_defaults.handlers,
    on_attach = lsp_defaults.on_attach,
}

local exceptions = { rust_analyzer = "rust-tools" }
for _, server in ipairs(servers) do
    local is_exception = false

    local opts = {
        capabilities = lsp_defaults.capabilities,
        handlers = lsp_defaults.handlers,
        on_attach = lsp_defaults.on_attach,
    }
    if lang_opts.enhanceable(server) then
        lang_opts.enhance(server, opts)
    end

    for exception, map in pairs(exceptions) do
        if server == exception then
            require(map).setup(opts)
            is_exception = true
        end
    end

    if not is_exception then
        require("lspconfig")[server].setup(opts)
    end
end

-- diagnostics
vim.diagnostic.config({
    virtual_text = {
        spacing = 2,
    },
})
