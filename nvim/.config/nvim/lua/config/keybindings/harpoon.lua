local M = {}

M.load_mappings = function()
  local s = { silent = true }
  local nor = { noremap = true }
  local nor_s = vim.tbl_extend("keep", nor, s)
  local map = vim.api.nvim_set_keymap

  map("n", "<c-c>", ":lua require('harpoon.ui').toggle_quick_menu()<cr>", nor_s)
  map("n", "<c-s-c>", ":lua require('harpoon.cmd-ui').toggle_quick_menu()<cr>", nor_s)

  map("n", "<a-s>", ":lua require('harpoon.ui').nav_file(1)<cr>", nor_s)
  map("n", "<a-t>", ":lua require('harpoon.ui').nav_file(2)<cr>", nor_s)
  map("n", "<a-n>", ":lua require('harpoon.ui').nav_file(3)<cr>", nor_s)
  map("n", "<a-e>", ":lua require('harpoon.ui').nav_file(4)<cr>", nor_s)
  map("n", "<a-s-s>", ":lua require('harpoon.ui').nav_file(5)<cr>", nor_s)
  map("n", "<a-s-t>", ":lua require('harpoon.ui').nav_file(6)<cr>", nor_s)
  map("n", "<a-s-n>", ":lua require('harpoon.ui').nav_file(7)<cr>", nor_s)
  map("n", "<a-s-e>", ":lua require('harpoon.ui').nav_file(8)<cr>", nor_s)

  map("n", "<leader>hq", ":lua require('harpoon.mark').to_quickfix_list()<cr>", nor)
  map("n", "<leader>ha", ":lua require('harpoon.mark').add_file()<cr>", nor)
  map("n", "<leader>hr", ":lua require('harpoon.mark').rm_file()<cr>", nor)
  map("n", "<leader>hc", ":lua require('harpoon.mark').clear_all()<cr>", nor)
  -- map("n", '<leader>htt', ":lua require("harpoon.tmux").sendCommand('{down-of}', 1)<cr>", nor_s)

  -- map("n", "<leader>hk", ":lua require('harpoon.cmd-ui').nav_next()<cr>", nor_s)
  -- map("n", "<leader>hK", ":lua require('harpoon.cmd-ui').nav_prev()<cr>", nor_s)

  -- clear terminal
  -- map("n", "<leader>hCt", ":lua require('harpoon.term').clear_all()<cr>", nor_s)
  -- map("n", '<leader>htt', ":lua require('harpoon.tmux').sendCommand(1, 'ls -la')<cr>", nor_s)
  -- map("n", '<leader>htt', ":lua require('harpoon.tmux').sendCommand(1, 'ls -la')<cr>", nor_s)
end

return M
