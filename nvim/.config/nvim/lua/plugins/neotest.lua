local function req(module)
    return function(name, opts)
        require(module)
    end
end
return {
    {
        "nvim-neotest/neotest",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
            "vim-test/vim-test",
            "nvim-neotest/neotest-vim-test",
            "nvim-neotest/neotest-go",
            "nvim-neotest/neotest-python",
        },
        config = req "config.plugins.neotest",
        -- lazy.nvim's `module` field was deprecated; loading is driven by
        -- the require calls in the config function and any `require("neotest")`
        -- in user keybindings.
        cmd = { "Neotest" },
        keys = {
            { "St",  desc = "neotest" },
        },
    },
}
