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
  -- clear marks
  map("n", "<leader>hCh", ":lua require('harpoon.mark').clear_all()<cr>", nor)

  map("n", "<c-c>", ":lua require('harpoon.ui').toggle_quick_menu()<cr>", nor_s)
  map("n", "<c-s-c>", ":lua require('harpoon.cmd-ui').toggle_quick_menu()<cr>", nor_s)
  map("n", "<leader>hh", ":lua require('harpoon.ui').toggle_quick_menu()<cr>", nor_s)
  map("n", "<leader>hH", ":lua require('harpoon.cmd-ui').toggle_quick_menu()<cr>", nor_s)
  map("n", "<leader>hc", ":lua require('harpoon.cmd-ui').toggle_quick_menu()<cr>", nor_s)

  map("n", "<leader>hk", ":lua require('harpoon.cmd-ui').nav_next()<cr>", nor_s)
  map("n", "<leader>hK", ":lua require('harpoon.cmd-ui').nav_prev()<cr>", nor_s)

  -- clear terminal
  map("n", "<leader>hCt", ":lua require('harpoon.term').clear_all()<cr>", nor_s)

  -- map("n", "<leader>ht!", ":lua require('harpoon.term').sendCommand(1, 1)<cr>", nor_s)
  map("n", '<leader>htt', ":lua require('harpoon.tmux').sendCommand(1, 'ls -la')<cr>", nor_s)
  -- map("n", "<leader>ht!", ":lua require('harpoon.term').sendCommand(1, 'ls -la')<cr>", nor_s)

  -- you can use <leader>1-9 for commands
  if vim.fn.getenv("TMUX") ~= vim.NIL then
    -- lua require("harpoon.tmux").gotoTerminal(1)             -- goes to the first tmux window
    -- lua require("harpoon.tmux").sendCommand(1, "ls -La")    -- sends ls -La to tmux window 1
    -- lua require("harpoon.tmux").sendCommand(1, 1)           -- sends command 1 to tmux window 1
    -- lua require("harpoon.tmux").gotoTerminal("{down-of}")   -- focus the pane directly below
    -- lua require("harpoon.tmux").sendCommand("%3", "ls")     -- send a command to the pane with id '%3'
    -- map("n", "<leader>hP", ":lua require('harpoon.tmux').sendCommand(2, 1)<cr>", nor_s)

    map("n", "<c-a-s>", ":lua require('harpoon.tmux').sendCommand(1, 1)<cr>", nor)
    map("n", "<c-a-t>", ":lua require('harpoon.tmux').sendCommand(2, 2)<cr>", nor)
    map("n", "<c-a-n>", ":lua require('harpoon.tmux').sendCommand(3, 3)<cr>", nor)
    map("n", "<c-a-e>", ":lua require('harpoon.tmux').sendCommand(4, 4)<cr>", nor)

    -- map("n", "<leader>hs", ":lua require('harpoon.tmux').gotoTerminal(1)<cr>", nor_s)
    -- map("n", "<leader>ht", ":lua require('harpoon.tmux').gotoTerminal(2)<cr>", nor_s)
  else
    map("n", "<c-a-s>", ":lua require('harpoon.term').sendCommand(1, 1)<cr>", {})
    map("n", "<c-a-t>", ":lua require('harpoon.term').sendCommand(2, 2)<cr>", {})
    map("n", "<c-a-n>", ":lua require('harpoon.term').sendCommand(3, 3)<cr>", {})
    map("n", "<c-a-e>", ":lua require('harpoon.term').sendCommand(4, 4)<cr>", {})

    map("n", "<leader>h1", ":lua require('harpoon.term').sendCommand(1, '')<Left><Left>", nor)
    map("n", "<leader>h2", ":lua require('harpoon.term').sendCommand(2, '')<Left><Left>", nor)
    map("n", "<leader>h3", ":lua require('harpoon.term').sendCommand(3, '')<Left><Left>", nor)
    map("n", "<leader>h4", ":lua require('harpoon.term').sendCommand(4, '')<Left><Left>", nor)

    map("n", "<leader>hs", ":lua require('harpoon.term').gotoTerminal(1)<cr>", nor_s)
    map("n", "<leader>ht", ":lua require('harpoon.term').gotoTerminal(2)<cr>", nor_s)
    map("n", "<leader>hn", ":lua require('harpoon.term').gotoTerminal(2)<cr>", nor_s)
    map("n", "<leader>he", ":lua require('harpoon.term').gotoTerminal(2)<cr>", nor_s)
  end

  -- map("n", "<c-8>", ":lua require('harpoon.term').gotoTerminal(2)<cr>", nor_s)
  -- map("n", "<c-4>", ":lua require('harpoon.term').gotoTerminal(3)<cr>", nor_s)
  -- map("n", "<c-3>", ":lua require('harpoon.term').gotoTerminal(4)<cr>", nor_s)

  -- map("n", "<leader>%", ":lua require('harpoon.term').gotoTerminal(5)<cr>", nor_s)
  -- map("n", "<leader>&", ":lua require('harpoon.term').gotoTerminal(6)<cr>", nor_s)
  -- map("n", "<leader>/", ":lua require('harpoon.term').gotoTerminal(7)<cr>", nor_s)
  -- map("n", "<leader>(", ":lua require('harpoon.term').gotoTerminal(8)<cr>", nor_s)
  -- map("n", "<leader>)", ":lua require('harpoon.term').gotoTerminal(9)<cr>", nor_s)
  map("n", "<A-s>", ":lua require('harpoon.ui').nav_file(1)<cr>", nor_s)
  map("n", "<A-t>", ":lua require('harpoon.ui').nav_file(2)<cr>", nor_s)
  map("n", "<A-n>", ":lua require('harpoon.ui').nav_file(3)<cr>", nor_s)
  map("n", "<A-e>", ":lua require('harpoon.ui').nav_file(4)<cr>", nor_s)
  map("n", "<A-S-s>", ":lua require('harpoon.ui').nav_file(5)<cr>", nor_s)
  map("n", "<A-S-t>", ":lua require('harpoon.ui').nav_file(6)<cr>", nor_s)
  map("n", "<A-S-n>", ":lua require('harpoon.ui').nav_file(7)<cr>", nor_s)
  map("n", "<A-S-e>", ":lua require('harpoon.ui').nav_file(8)<cr>", nor_s)

  -- map("n", "<leader><a-s>", ":lua require('harpoon.ui').nav_file(5)<cr>", nor_s)
  -- map("n", "<leader><a-t>", ":lua require('harpoon.ui').nav_file(6)<cr>", nor_s)
  -- map("n", "<leader><a-n>", ":lua require('harpoon.ui').nav_file(7)<cr>", nor_s)
  -- map("n", "<leader><a-e>", ":lua require('harpoon.ui').nav_file(8)<cr>", nor_s)
end
return M
