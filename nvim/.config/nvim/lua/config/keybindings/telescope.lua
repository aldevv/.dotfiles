local M = {}
local s = { silent = true }
local nor = { noremap = true }
local nor_s = vim.tbl_extend("keep", nor, s)
local map = vim.api.nvim_set_keymap

M.load_mappings = function()
    -- telescope essential
    map("n", "<a-p>", ':lua require("telescope.builtin").find_files( {cwd = vim.fn.expand("%:p:h")} )<cr>', nor_s)
    map("n", "<a-b>", ':lua require("telescope.builtin").buffers()<cr>', nor_s)
    map("n", "<a-r>", ':lua require("telescope.builtin").live_grep()<cr>', nor_s)
    map("n", "<a-s-r>", ':lua require("telescope.builtin").grep_string()<cr>', nor_s)
    map("n", "<leader>sz", ':lua require("utils.lua.telescope").zenmode()<cr>', nor_s)

    -- t misc
    map("n", "<leader>to", ':lua require("telescope.builtin").oldfiles()<cr>', nor_s)
    map("n", "<leader>tj", ':lua require("telescope.builtin").jumplist()<cr>', nor_s)
    map("n", "<leader>tL", ':lua require("telescope.builtin").loclist()<cr>', nor_s)
    map("n", "<leader>tq", ':lua require("telescope.builtin").quickfix()<cr>', nor_s)
    map("n", "<leader>tr", ':lua require("telescope.builtin").registers()<cr>', nor_s)
    map("n", "<leader>ta", ':lua require("telescope.builtin").autocommands()<cr>', nor_s)
    map("n", "<leader>tk", ':lua require("telescope.builtin").keymaps()<cr>', nor_s)
    map("n", "<leader>tM", ':lua require("telescope.builtin").marks()<cr>', nor_s)
    map("n", "<leader>tm", ':lua require("telescope.builtin").man_pages()<cr>', nor_s)
    map("n", "<leader>th", ':lua require("telescope.builtin").help_tags()<cr>', nor_s)
    map("n", "<leader>tH", ':lua require("telescope.builtin").highlights()<cr>', nor_s)
    map("n", "<leader>tvo", ':lua require("telescope.builtin").vim_options()<cr>', nor_s)
    map("n", "<leader>tvc", ':lua require("telescope.builtin").commands()<cr>', nor_s)
    map("n", "<leader>tvC", ':lua require("telescope.builtin").colorscheme()<cr>', nor_s)
    map("n", "<leader>tvh", ':lua require("telescope.builtin").command_history()<cr>', nor_s)
    map("n", "<leader>ts", ':lua require("telescope.builtin").search_history()<cr>', nor_s)
    -- custom
    -- folders
    map("n", "<leader>tb", ':lua require("utils.lua.telescope").select_bg()<cr>', nor_s)
    map("n", "<a-s-p>", ':lua require("utils.lua.telescope").git_files_or_cwd()<cr>', nor_s)
    map("n", "<localleader>f.", ':lua require("utils.lua.telescope").dotfiles()<cr>', nor_s)
    map("n", "<localleader>v.", ':lua require("utils.lua.telescope").nvim()<cr>', nor_s)
    map("n", "<localleader>vk", ':lua require("utils.lua.telescope").nvim({path = "lua/config/keybindings"})<cr>', nor_s)
    map("n", "<localleader>vc", ':lua require("utils.lua.telescope").nvim({path = "lua/config/"})<cr>', nor_s)
    map("n", "<localleader>vC", ':lua require("utils.lua.telescope").nvim({path = "lua/core/"})<cr>', nor_s)
    map("n", "<localleader>vu", ':lua require("utils.lua.telescope").nvim({path = "lua/utils/"})<cr>', nor_s)
    map("n", "<localleader>vl", ':lua require("utils.lua.telescope").nvim({path = "lua/lsp/"})<cr>', nor_s)
    map("n", "<localleader>vp", ':lua require("utils.lua.telescope").plugins_def()<cr>', nor_s)
    map("n", "<localleader>ms", ':lua require("utils.lua.telescope").scripts()<cr>', nor_s)
    map("n", "<localleader>mf", ':lua require("utils.lua.telescope").files()<cr>', nor_s)
    map("n", "<localleader>mu", ':lua require("utils.lua.telescope").utilities()<cr>', nor_s)
    map("n", "<localleader>MM", ':lua require("utils.lua.telescope").main()<cr>', nor_s)
    map("n", "<localleader>mi", ':lua require("utils.lua.telescope").micro()<cr>', nor_s)
    map("n", "<localleader>cc", ':lua require("utils.lua.telescope").classes()<cr>', nor_s)
    map("n", "<localleader>ll", ':lua require("utils.lua.telescope").learn()<cr>', nor_s)
    map("n", "<localleader>Md", ':lua require("utils.lua.telescope").playground()<cr>', nor_s)
    map("n", "<localleader>.ex", ':lua require("utils.lua.telescope").exploits()<cr>', nor_s)

    -- deprecated 05/01/2022
    -- map('n', '<a-f>', ':lua require("telescope.builtin").file_browser()<cr>',nor_s) https://github.com/nvim-telescope/telescope-file-browser.nvim/issues/3

    map("n", "<leader>tt", ":Telescope<cr>", nor_s)
    -- t core
    map("n", "<leader>tch", ":Telescope harpoon marks<cr>", nor_s)


    -- telescope lsp
    map("n", "<leader>tlr", ':lua require("telescope.builtin").lsp_references()<cr>', nor_s)
    map("n", "<leader>tls", ':lua require("telescope.builtin").lsp_document_symbols()<cr>', nor_s)
    map("n", "<leader>tlS", ':lua require("telescope.builtin").lsp_dynamic_workspace_symbols()<cr>', nor_s)
    map("n", "<leader>tla", ':lua require("telescope.builtin").lsp_code_actions()<cr>', nor_s)
    map("v", "<leader>tla", ':lua require("telescope.builtin").lsp_range_code_actions()<cr>', nor_s)
    map("n", "<leader>tlt", ':lua require("telescope.builtin").lsp_type_definitions()<cr>', nor_s)
    map("n", "<leader>tli", ':lua require("telescope.builtin").lsp_implementations()<cr>', nor_s)
    map("n", "<leader>tld", ':lua require("telescope.builtin").lsp_definitions()<cr>', nor_s)
    map("n", "<leader>tlD", ':lua require("telescope.builtin").diagnostics()<cr>', nor_s)
    map("n", "<leader>tws", ':lua require("telescope.builtin").lsp_workspace_symbols()<cr>', nor_s)

    -- telescope git
    map("n", "<leader>tgc", ':lua require("telescope.builtin").git_commits()<cr>', nor_s)
    -- 	Lists git commits with diff preview, checkout action <cr>, reset mixed <C-r>m, reset soft <C-r>s and reset hard <C-r>h
    map("n", "<leader>tgC", ':lua require("telescope.builtin").git_bcommits()<cr>', nor_s)
    -- 	Lists buffer's git commits with diff preview and checks them out on <cr>

    map("n", "<leader>tgb", ':lua require("telescope.builtin").git_branches()<cr>', nor_s)
    map("n", "<leader>tgs", ':lua require("telescope.builtin").git_status()<cr>', nor_s)
    map("n", "<leader>tgS", ':lua require("telescope.builtin").git_stash()<cr>', nor_s)

    map("n", "<leader>tp", ":Telescope projects<cr>", nor) -- recently opened porjects!!
end
return M
