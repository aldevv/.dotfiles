local null_ls = require("null-ls")
local formatting = null_ls.builtins.formatting
local diagnostics = null_ls.builtins.diagnostics
local completion = null_ls.builtins.completion
local code_actions = null_ls.builtins.code_actions

-- it can be disabled like this
-- if vim.g.started_by_firenvim then
--     vim.g.null_ls_disable = true
-- end

-- config docs
--https://github.com/jose-elias-alvarez/null-ls.nvim/blob/1e131a0b3f52eb812c7c07f5e24aee90c0ee8967/doc/CONFIG.md
--sources
--https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/SOURCES.md
--here are the individual files
-- ~/.local/share/nvim/site/pack/packer/start/null-ls.nvim/lua/null-ls/builtins/formatting
local opts = {
    -- Displays all possible log messages and writes them to the null-ls log, which you can view with the command :NullLsLog. This option can slow down Neovim, so it's strongly recommended to disable it for normal use.
    -- debug = false,
    debug = false,
    log = {
        enable = false,
        level = "warn",
        use_console = "async",
    },
    on_attach = function(client, bufnr) end,
    -- conf options
    -- https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md
    sources = {
        -- formatting.isort,
        formatting.black.with({ extra_args = { "--fast" } }),
        -- formatting.isort,
        formatting.gofmt,
        -- formatting.uncrustify,
        formatting.clang_format,
        -- formatting.json_tool, jsonls already has one
        formatting.prettier,
        diagnostics.vint, --> for vim
        -- formatting.eslint_d,
        -- it looks for node_modules automatically, if you prefer a local in a different place,
        -- then set it using prefer_local
        diagnostics.eslint,
        -- prefer_local = "node_modules/.bin",
        -- prefer_local = true,
        -- }),
        --     condition = function(utils)
        --     return utils.root_has_file_matches(".eslintrc*")
        -- end,
        -- }),
        -- diagnostics.eslint_d,
        -- diagnostics.eslint_d.with({
        --     condition = function(utils)
        -- return utils.root_has_file({ ".eslintrc.json" })
        --     end,
        -- }),
        -- diagnostics.selene,
        -- formatting.eslint,
        -- diagnostics.eslint,
        -- formatting.prettier,
        -- my flake config
        -- diagnostics.flake8.with({ extra_args = { "--ignore", "E203", "--max-line-length", "88" } }), -- extra args for black
        -- completion.spell,
        code_actions.gitsigns,
        -- code_actions.eslint_d,
        code_actions.refactoring,
        code_actions.shellcheck,
    },
}
local format_servers = {
    "shfmt",
    "black",
    "stylua",
    "gofmt",
}
local diagnostic_servers = {
    "shellcheck",
    "flake8",
}
local servers = vim.tbl_extend("force", format_servers, diagnostic_servers)

require("mason-null-ls").setup({
    ensure_installed = servers,
    automatic_setup = true,
})

-- TODO: change to this new way of doing it
-- require ('mason-null-ls').setup({
--     ensure_installed = {'stylua', 'jq'}
--     handlers = {
--         function() end, -- disables automatic setup of all null-ls sources
--         stylua = function(source_name, methods)
--           null_ls.register(null_ls.builtins.formatting.stylua)
--         end,
--         shfmt = function(source_name, methods)
--           -- custom logic
--           require('mason-null-ls').default_setup(source_name, methods) -- to maintain default behavior
--         end,
--     },
-- })

require("mason-null-ls").setup_handlers({
    function(source_name, methods)
        require("mason-null-ls.automatic_setup")(source_name, methods)
    end,
    stylua = function(source_name, methods)
        null_ls.register(formatting.stylua.with({ extra_args = { "--indent-type", "Spaces" } }))
    end,
    shfmt = function(source_name, methods)
        null_ls.register(formatting.shfmt.with({
            extra_filetypes = { "zsh", "bash" },
        }))
    end,
    shellcheck = function(source_name, methods)
        null_ls.register(diagnostics.shellcheck.with({ extra_filetypes = { "zsh", "bash" } }))
    end,
})

null_ls.setup(opts)
