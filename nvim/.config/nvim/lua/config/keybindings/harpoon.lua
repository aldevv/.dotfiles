local M = {}

M.load_mappings = function()
    local s = { silent = true }
    local nor = { noremap = true }
    local nor_s = vim.tbl_extend("keep", nor, s)
    local map = vim.api.nvim_set_keymap

    -- harpoon
    --.require('harpoon.mark').set_mark_list(new_list) -- use it in your custom .vimrc per project
    --require('harpoon.mark').toggle_file for no add and rm
    map("n", "<leader>hq", ":lua require('harpoon.mark').to_quickfix_list()<cr>", nor)
    map("n", "<leader>ha", ":lua require('harpoon.mark').add_file()<cr>", nor)
    map("n", "<leader>hr", ":lua require('harpoon.mark').rm_file()<cr>", nor)
    map("n", "<leader>hc", ":lua require('harpoon.mark').clear_all()<cr>", nor)

    map("n", "<leader>hh", ":lua require('harpoon.ui').toggle_quick_menu()<cr>", nor_s)
    map("n", "<leader>htt", ":lua require('harpoon.cmd-ui').toggle_quick_menu()<cr>", nor_s)

    map("n", "<leader>hk", ":lua require('harpoon.cmd-ui').nav_next()<cr>", nor_s)
    map("n", "<leader>hK", ":lua require('harpoon.cmd-ui').nav_prev()<cr>", nor_s)

    map("n", "<leader>htc", ":lua require('harpoon.term').clear_all()<cr>", nor_s)

    map("n", "<leader>ht!", ":lua require('harpoon.term').sendCommand(1, 1)<cr>", nor_s)
    map("n", '<leader>ht"', ":lua require('harpoon.term').sendCommand(1, 'ls -la')<cr>", nor_s)
    -- map("n", "<leader>ht!", ":lua require('harpoon.term').sendCommand(1, 'ls -la')<cr>", nor_s)

    -- you can use <leader>1-9 for commands
    if vim.fn.getenv("TMUX") ~= vim.NIL then
        map("n", "<leader>hF", ":lua require('harpoon.tmux').sendCommand(1, 1)<cr>", nor_s)
        map("n", "<leader>hP", ":lua require('harpoon.tmux').sendCommand(2, 1)<cr>", nor_s)

        map("n", "<leader>hf", ":lua require('harpoon.tmux').sendCommand(1, '')<left><left>", nor)
        map("n", "<leader>hp", ":lua require('harpoon.tmux').sendCommand(2, '')<left><left>", nor)

        map("n", "<leader>hs", ":lua require('harpoon.tmux').gotoTerminal(1)<cr>", nor_s)
        map("n", "<leader>ht", ":lua require('harpoon.tmux').gotoTerminal(2)<cr>", nor_s)
    else
        map("n", "<leader>hF", ":lua require('harpoon.term').sendCommand(1, 1)<cr>", nor_s)
        map("n", "<leader>hP", ":lua require('harpoon.term').sendCommand(2, 1)<cr>", nor_s)

        map("n", "<leader>hf", ":lua require('harpoon.term').sendCommand(1, '')<Left><Left>", nor)
        map("n", "<leader>hp", ":lua require('harpoon.term').sendCommand(2, '')<Left><Left>", nor)

        map("n", "<leader>hs", ":lua require('harpoon.term').gotoTerminal(1)<cr>", nor_s)
        map("n", "<leader>ht", ":lua require('harpoon.term').gotoTerminal(2)<cr>", nor_s)
    end

    -- map("n", "<c-8>", ":lua require('harpoon.term').gotoTerminal(2)<cr>", nor_s)
    -- map("n", "<c-4>", ":lua require('harpoon.term').gotoTerminal(3)<cr>", nor_s)
    -- map("n", "<c-3>", ":lua require('harpoon.term').gotoTerminal(4)<cr>", nor_s)

    -- map("n", "<leader>%", ":lua require('harpoon.term').gotoTerminal(5)<cr>", nor_s)
    -- map("n", "<leader>&", ":lua require('harpoon.term').gotoTerminal(6)<cr>", nor_s)
    -- map("n", "<leader>/", ":lua require('harpoon.term').gotoTerminal(7)<cr>", nor_s)
    -- map("n", "<leader>(", ":lua require('harpoon.term').gotoTerminal(8)<cr>", nor_s)
    -- map("n", "<leader>)", ":lua require('harpoon.term').gotoTerminal(9)<cr>", nor_s)

    map("n", "<c-s>", ":lua require('harpoon.ui').nav_file(1)<cr>", nor_s)
    map("n", "<c-t>", ":lua require('harpoon.ui').nav_file(2)<cr>", nor_s)
    map("n", "<c-n>", ":lua require('harpoon.ui').nav_file(3)<cr>", nor_s)
    map("n", "<c-e>", ":lua require('harpoon.ui').nav_file(4)<cr>", nor_s)

    map("n", "<leader><c-s>", ":lua require('harpoon.ui').nav_file(5)<cr>", nor_s)
    map("n", "<leader><c-t>", ":lua require('harpoon.ui').nav_file(6)<cr>", nor_s)
    map("n", "<leader><c-n>", ":lua require('harpoon.ui').nav_file(7)<cr>", nor_s)
    map("n", "<leader><c-e>", ":lua require('harpoon.ui').nav_file(8)<cr>", nor_s)
end
return M
