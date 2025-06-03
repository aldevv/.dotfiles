local s = { silent = true }
local nor = { noremap = true }
local e = { expr = true }
local s_e = vim.tbl_extend("keep", s, e)

local nor_s = vim.tbl_extend("keep", nor, s)
local nor_e = vim.tbl_extend("keep", nor, e)
local nor_e_s = vim.tbl_extend("keep", nor, e, s)


local desc = function(desc)
  return vim.tbl_extend("keep", nor_s, { desc = desc })
end

local descv = function(desc)
  return vim.tbl_extend("keep", nor, { desc = desc })
end

local map = vim.keymap.set

map({ "n", "v" }, "<C-a>", "<cmd>CodeCompanionActions<cr>", nor_s)
map({ "n", "v" }, "Sa", "<cmd>CodeCompanionChat Toggle<cr>", nor_s)
map("v", "ga", "<cmd>CodeCompanionChat Add<cr>", nor_s)

-- Expand 'cc' into 'CodeCompanion' in the command line
vim.cmd([[cabbrev cc CodeCompanion]])
