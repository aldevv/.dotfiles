local cfg = {
  global_settings = {
    enter_on_sendcmd = true,
    -- set marks specific to each git branch inside git repository
    -- mark_branch = false,
  },
}
local ok, work = pcall(require, "work")
if ok then
  local projects = {}
  projects = work.harpoon_projects
  cfg = vim.tbl_extend("keep", cfg, projects)
end

require("harpoon").setup(cfg)

local ok, telescope = pcall(require, "telescope")
if not ok then
  return
end
telescope.load_extension("harpoon")
-- projects = {
--     ["$HOME/work/project/{}"] = {
--         mark = {
--             marks = {
--                 {
--                     col = 44,
--                     row = 21,
--                     filename = "folder1/file1.go",
--                 },
--                 {
--                     col = 6,
--                     row = 458,
--                     filename = "folder2/file2.go",
--                 },
--                 {
--                     col = 29,
--                     row = 22,
--                     filename = "folder3/file3.go",
--                 },
--                 {
--                     col = 0,
--                     row = 32,
--                     filename = "test/folder4/file4.go",
--                 },
--                 {
--                     col = 1,
--                     row = 79,
--                     filename = "test/folder5/file5.go",
--                 },
--             },
--         },
--         term = {
--             cmds = {
--                 "make",
--                 "make install",
--             },
--         },
--     },
-- },

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
