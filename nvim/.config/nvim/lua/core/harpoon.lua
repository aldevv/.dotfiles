require("harpoon").setup({})
-- require("harpoon").setup({
--     -- sets harpoon to run the command immediately as it's passed to the terminal when calling `sendCommand`.
--     global_settings = {
--         -- sets the marks upon calling `toggle` on the ui, instead of require `:w`.
--         save_on_toggle = false,
--
--         -- saves the harpoon file upon every change. disabling is unrecommended.
--         save_on_change = true,
--
--         -- sets harpoon to run the command immediately as it's passed to the terminal when calling `sendCommand`.
--         enter_on_sendcmd = false,
--
--         -- closes any tmux windows harpoon that harpoon creates when you close Neovim.
--         tmux_autoclose_windows = false,
--
--         -- filetypes that you want to prevent from adding to the harpoon list menu.
--         excluded_filetypes = { "harpoon" },
--
--         -- set marks specific to each git branch inside git repository
--         mark_branch = false,
--     },
--
--     nav_first_in_list = true,
--     projects = {
--         -- Yes $HOME works
--         ["$PROJECTS/main/"] = {
--             term = {
--                 cmds = {
--                     "yarn dev",
--                 },
--             },
--         },
--         ["$PROJECTS/micro/"] = {
--             term = {
--                 cmds = {
--                     "yarn dev",
--                 },
--             },
--         },
--     },
-- })
--
require("telescope").load_extension("harpoon")
