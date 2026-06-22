local function req(module)
    return function(name, opts)
        require(module)
    end
end
return {
    {
        "mattn/emmet-vim",
        init = function()
            -- vim.g.user_emmet_install_global = 0
        end,
        config = function()
            vim.keymap.set("i", "€", "<plug>(emmet-expand-abbr)")
        end,
        ft = { "html", "js", "javascriptreact", "typescriptreact", "ts", "css", "vue", "svelte", "jsx", "tsx" },
    },
    {
        "NvChad/nvim-colorizer.lua",
        ft = { "css", "scss", "html", "lua", "vim", "javascript", "typescript", "javascriptreact", "typescriptreact", "yaml", "tmux", "conf" },
        config = function()
            require("colorizer").setup({
                filetypes = { "css", "scss", "html", "lua", "vim", "javascript", "typescript", "javascriptreact", "typescriptreact", "yaml", "tmux", "conf" },
            })
        end,
    },
    {
        "windwp/nvim-ts-autotag",
        ft = { "html", "javascriptreact", "typescriptreact", "vue", "svelte", "xml", "jsx", "tsx" },
        config = function()
            require("nvim-ts-autotag").setup()
        end,
    },
}
