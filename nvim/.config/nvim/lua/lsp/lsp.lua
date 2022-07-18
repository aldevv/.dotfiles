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

local lsp_installer = require("nvim-lsp-installer")
lsp_installer.setup({ automatic_installation = true })
local lspconfig = require("lspconfig")
local lsp_defaults = require("lsp.lsp_defaults")
local lang_opts = require("lsp.lang_opts")

for _, server in ipairs(servers) do
    -- for _, server in ipairs(lsp_installer.get_installed_servers()) do
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

-- lspconfig.sqls.setup({
--     on_attach = function(client, bufnr)
--         require("sqls").on_attach(client, bufnr)
--         vim.keymap.set("n", "<cr>", "<cmd>SqlsExecuteQuery<cr>", { buffer = 0 })
--     end,
-- })
