-- xpm settings

require("xpm").setup({
    plugins = {
        -- Let xpm manage itself
        "dtomvan/xpm.xplr",
        { name = "sayanarijit/fzf.xplr" },

        {
            "prncss-xyz/icons.xplr",
            setup = function()
                require("icons").setup()
            end,
        },
        {
            "dtomvan/extra-icons.xplr",
            after = function()
                xplr.config.general.table.row.cols[2] = { format = "custom.icons_dtomvan_col_1" }
            end,
        },
        {
            "sayanarijit/map.xplr",
            setup = function()
                --Visually inspect and interactively execute batch commands using xplr. It's like xargs.xplr but better.
                --Tip: This plugin can be used with find.xplr.
                require("map").setup()
            end,
        },
        {
            "sayanarijit/dragon.xplr",
            setup = function()
                require("dragon").setup({
                    mode = "selection_ops",
                    key = "b",
                    drag_args = "",
                    drop_args = "",
                    keep_selection = false,
                    bin = "dragon",
                })
            end,
        },
    },
    auto_install = true,
    auto_cleanup = true,
})
