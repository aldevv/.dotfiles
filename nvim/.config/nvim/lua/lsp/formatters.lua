local null_ls = require("null-ls")
local formatting = null_ls.builtins.formatting
local diagnostics = null_ls.builtins.diagnostics
local completion = null_ls.builtins.completion
local code_actions = null_ls.builtins.code_actions

-- config docs
--https://github.com/jose-elias-alvarez/null-ls.nvim/blob/1e131a0b3f52eb812c7c07f5e24aee90c0ee8967/doc/CONFIG.md
--https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/SOURCES.md
--https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md

local opts = {
    debug = false,
    log = {
        enable = false,
        level = "warn",
        use_console = "async",
    },
    on_attach = function(client, bufnr) end,
    sources = {
        formatting.black.with({ extra_args = { "--fast" } }),
        formatting.gofmt,
        formatting.clang_format,
        formatting.prettier,
        diagnostics.vint, --> for vim
        diagnostics.eslint,
        code_actions.gitsigns,
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

local handlers = {
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
}
require("mason-null-ls").setup({
    ensure_installed = servers,
    automatic_setup = true,
    handlers = handlers,
})

null_ls.setup(opts)
