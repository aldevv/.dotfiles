-- require("nvim-lsp-installer").setup {
--   automatic_installation = true
-- }

-- local lspconfig = require("lspconfig")
--
-- lspconfig.pyright.setup({})
-- vim.lsp.set_log_level("trace")
require("nvim-lsp-setup").setup({
    servers = {
        pyright = {},
        bashls = {},
        clangd = {},
        -- "pylsp", -- snippets completion
        html = {},
        cssls = {},
        jdtls = {}, -- java
        zk = {}, -- markdown
        tsserver = {},
        -- "tailwindcss",
        svelte = {},
        sumneko_lua = {},
        vimls = {},
        gopls = {},
        dockerls = {},
        jsonls = {},
        -- "yamlls",
        rust_analyzer = {},
        volar = {}, -- vue
        sqls = {},
        hls = {},
        solargraph = {}, -- ruby
        emmet_ls = {},
        graphql = {},
    },
})
