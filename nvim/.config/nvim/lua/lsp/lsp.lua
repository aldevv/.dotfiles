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
    "lua_ls",
    "vimls",
    "gopls",
    "dockerls",
    "jsonls",
    "rust_analyzer",
    "volar",
    -- "eslint-lsp"
    -- "sqls",
    --    "hls",
    "emmet_ls",
}

require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = servers,
    automatic_installation = true,
})

local get_opts = function()
    local lsp_defaults = require("lsp.lsp_defaults")
    return {
        capabilities = lsp_defaults.capabilities,
        handlers = lsp_defaults.handlers,
        on_attach = lsp_defaults.on_attach,
    }
end

local enhance_server = function(server, opts)
    local lang_opts = require("lsp.lang_opts")
    if lang_opts.enhanceable(server) then
        lang_opts.enhance(server, opts)
    end
end

require("mason-lspconfig").setup_handlers({
    function(server_name) -- default handler (optional)
        local opts = get_opts()
        enhance_server(server_name, opts)
        require("lspconfig")[server_name].setup(opts)
    end,
    ["rust_analyzer"] = function()
        local opts = get_opts()
        enhance_server("rust_analyzer", opts)
        require("rust-tools").setup(opts)
    end,
})
