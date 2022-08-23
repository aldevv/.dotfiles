-- ===========
-- LSP
-- ===========
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
    "volar", -- vue
    "sqls",
    "hls",
    "emmet_ls",
    "graphql",
    -- "tailwindcss",
    -- "pylsp", -- snippets completion
    -- "yamlls",
    -- "solargraph", -- ruby
    -- "zk", -- markdown
    -- "jdtls", -- java
}

require("mason").setup()
require("mason-lspconfig").setup({
    automatic_installation = true,
    ensure_installed = servers,
})

local lspconfig = require("lspconfig")
local lsp_defaults = require("lsp.lsp_defaults")
local lang_opts = require("lsp.lang_opts")

for _, server in ipairs(servers) do
    local opts = {
        capabilities = lsp_defaults.capabilities,
        handlers = lsp_defaults.handlers,
        on_attach = lsp_defaults.on_attach,
    }

    if lang_opts.enhanceable(server) then
        lang_opts.enhance(server, opts)
    end
    lspconfig[server].setup(opts)
end

-- diagnostics
vim.diagnostic.config({
    -- virtual_text = true,
    virtual_text = {
        spacing = 2,
    },
})
