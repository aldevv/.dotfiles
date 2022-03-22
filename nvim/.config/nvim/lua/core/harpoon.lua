-- HARPOON_LOG=trace nvim .
-- vim.g.harpoon_log_level = "trace"
require("harpoon").setup({
    -- sets harpoon to run the command immediately as it's passed to the terminal when calling `sendCommand`.
    global_settings = {
        enter_on_sendcmd = true,
    },

    nav_first_in_list = true,
    projects = {
        -- Yes $HOME works
        ["$PROJECTS/main/"] = {
            term = {
                cmds = {
                    "yarn dev",
                },
            },
        },
        ["$PROJECTS/micro/"] = {
            term = {
                cmds = {
                    "yarn dev",
                },
            },
        },
    },
})

require("telescope").load_extension("harpoon")
