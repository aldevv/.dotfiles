local M = {}
-- :h lspconfig-root-advanced
-- :h lspconfig-root-composition
local util = require("lspconfig.util")
local configs = require("lspconfig.configs")
local nvim_paths = vim.tbl_extend(
    "keep",
    vim.api.nvim_get_runtime_file("", true),
    { vim.fn.expand("$VIMRUNTIME/lua/vim"), vim.fn.expand("$VIMRUNTIME/lua/vim/lsp") }
)

local runtime_path = vim.split(package.path, ";")
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")

-- local runtime_path = vim.split(package.path, ";")
-- table.insert(runtime_path, "lua/?.lua")
-- table.insert(runtime_path, "lua/?/init.lua")
local enhance_server_opts = {
    ["bashls"] = function(opts)
        opts.filetypes = { "sh", "zsh", "bash" }
    end,
    ["sqls"] = function(opts)
        require("lsp.languages.sqls").exec(opts)
    end,
    ["tsserver"] = function(opts)
        -- :h lspconfig-root-advanced
        -- :h lspconfig-root-composition
        -- root_dir is a function
        --
        -- :h lspconfig-root-dir
        opts.root_dir = function(fname)
            return util.root_pattern("tsconfig.json")(fname)
                or util.root_pattern("package.json", "jsconfig.json", ".git", ".projections.json")(fname)
        end
    end,
    ["pyright"] = function(opts)
        -- add dap keybindings to python
        -- #TODO check why using a decorator or calling the func here, makes it fail when
        -- # opening a project from the root (like nvim .) and then entering a folder
        -- old_on_attach = opts.on_attach
        opts.on_attach = function(client, bufnr)
            -- require("config.keybindings.lsp").load_mappings()
            -- require("config.automation.lsp").diagnostics_in_loclist()
            -- client.server_capabilities.document_formatting = false
            -- client.server_capabilities.document_range_formatting = false

            -- old_on_attach(client, bufnr)
            local lang_opts = require("lsp.lsp_defaults")
            lang_opts.on_attach(client, bufnr)
            vim.pretty_print(opts)

            vim.keymap.set(
                "n",
                "<localleader>dlm",
                "<cmd>lua require('dap-python').test_method()<cr>",
                { noremap = true, silent = true }
            )
            vim.keymap.set(
                "n",
                "<localleader>dlc",
                "<cmd>lua require('dap-python').test_class()<cr>",
                { noremap = true, silent = true }
            )
            -- old_on_attach(client, bufnr)
        end
    end,
    ["pylsp"] = function(opts)
        opts.settings = {
            pylsp = {
                plugins = {
                    jedi_completion = {
                        include_params = true, -- this line enables snippets
                    },
                },
            },
        }
    end,
    ["clangd"] = function(opts)
        opts.capabilities.offsetEncoding = { "utf-16" }
    end,
    -- ["gopls"] = function(opts)
    --     opts.on_attach = function(client, buffnr)
    --         client.server_capabilities.document_formatting = false
    --         client.server_capabilities.document_range_formatting = false
    --     end
    -- end,

    ["sumneko_lua"] = function(opts)
        -- local runtime_path = vim.split(package.path, ";")
        -- table.insert(runtime_path, "lua/?.lua")
        -- table.insert(runtime_path, "lua/?/init.lua")

        opts.root_dir = util.root_pattern("apm.csv") or util.path.dirname(fname)
        opts.settings = {
            Lua = {
                runtime = {
                    -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                    version = "LuaJIT",
                    -- Setup your lua path
                    -- path = runtime_path,
                    path = runtime_path,
                },
                diagnostics = {
                    globals = { "vim" },
                },
                workspace = {
                    library = nvim_paths,
                    -- library = vim.list_extend(
                    --     "keep",
                    --     vim.api.nvim_get_runtime_file("", true),
                    --     vim.fn.expand("$VIMRUNTIME/lua/vim/lsp"),
                    --     vim.fn.expand("$VIMRUNTIME/lua/vim/")
                    -- Make the server aware of Neovim runtime files
                    -- library = vim.api.nvim_get_runtime_file("", true),
                    -- [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
                    -- [vim.fn.expand("$VIMRUNTIME/lua/vim/")] = true,

                    -- )
                },
            },
        }
    end,

    ["eslintls"] = function(opts)
        opts.settings = {
            format = {
                enable = true,
            },
        }
    end,
}
function M.enhanceable(name)
    for key, _ in pairs(enhance_server_opts) do
        if name == key then
            return true
        end
    end
    return false
end

function M.enhance(name, opts)
    enhance_server_opts[name](opts)
end

return M
