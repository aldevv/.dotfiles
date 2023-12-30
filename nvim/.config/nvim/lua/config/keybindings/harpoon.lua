local M = {}

M.load_mappings = function()
  local s = { silent = true }
  local nor = { noremap = true }
  local nor_s = vim.tbl_extend("keep", nor, s)
  local map = vim.keymap.set

  local harpoon = require("harpoon")

  map("n", "<leader><esc>", function() harpoon:list():append() end)
  map("n", "<leader><s-esc>", function() harpoon:list():clear() end)

  map("n", "<C-c>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
  map("n", "<C-s-c>", function() harpoon.ui:toggle_quick_menu(harpoon:list("term")) end)
  map("n", "<C-s-l>", function() harpoon.ui:toggle_quick_menu(harpoon:list("vimcmd")) end)

  map("n", "<a-s>", function() harpoon:list():select(1) end)
  map("n", "<a-t>", function() harpoon:list():select(2) end)
  map("n", "<a-n>", function() harpoon:list():select(3) end)
  map("n", "<a-e>", function() harpoon:list():select(4) end)

  map("n", "<a-s-s>", function() harpoon:list():select(5) end)
  map("n", "<a-s-t>", function() harpoon:list():select(6) end)
  map("n", "<a-s-n>", function() harpoon:list():select(7) end)
  map("n", "<a-s-e>", function() harpoon:list():select(8) end)

  map("n", "ñs", function() harpoon:list("term"):select(1) end)
  map("n", "ñt", function() harpoon:list("term"):select(2) end)
  map("n", "ñn", function() harpoon:list("term"):select(3) end)
  map("n", "ñe", function() harpoon:list("term"):select(4) end)
end

return M
