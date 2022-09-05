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

local no_defaults = { "rust_analyzer" }
require("mason-lspconfig").setup_handlers({
    function(server)
        for _, exception in ipairs(no_defaults) do
            if server == exception then
                return
            end
        end

        if lang_opts.enhanceable(server) then
            lang_opts.enhance(server, opts)
        end
        require("lspconfig")[server].setup(opts)
    end,

    ["rust_analyzer"] = function()
        require("rust-tools").setup({
            server = {
                capabilities = opts.capabilities,
                handlers = opts.handlers,
                on_attach = function(cl, bufnr)
                    opts.on_attach(cl, bufnr)
                    -- hover
                    vim.keymap.set("n", "+", require("rust-tools").hover_actions.hover_actions, { buffer = bufnr })
                    -- Code action groups
                    vim.keymap.set(
                        "n",
                        "<Leader>la",
                        require("rust-tools").code_action_group.code_action_group,
                        { buffer = bufnr }
                    )
                end,
            },
        })
    end,
})

-- diagnostics
vim.diagnostic.config({
    virtual_text = {
        spacing = 2,
    },
})
