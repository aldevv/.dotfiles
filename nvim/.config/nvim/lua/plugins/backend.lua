return {

    {
        "ray-x/go.nvim",
        commit = "a8095eb334495caec3099b717cc7f5b1fbc3e628",
        dependencies = { -- optional packages
            "ray-x/guihua.lua",
            "neovim/nvim-lspconfig",
            "nvim-treesitter/nvim-treesitter",
        },
        config = function()
            require("go").setup {
                run_in_floaterm = false,
            }
        end,
        event = { "CmdlineEnter" },
        ft = { "go", "gomod" },
        build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
    },
    {
        "mrcjkb/rustaceanvim",
        version = "^3", -- Recommended
        ft = { "rust" },
    },
    {
        "mrcjkb/haskell-tools.nvim",
        config = nil,
        branch = "2.x.x", -- recommended
        lazy = true,
    },
}
