local s = { silent = true }
local nor = { noremap = true }
local e = { expr = true }
local b = { buffer = true }
local s_e = vim.tbl_extend("keep", s, e)
local nb = vim.tbl_extend("keep", nor, b)

local nor_s = vim.tbl_extend("keep", nor, s)
local nor_e = vim.tbl_extend("keep", nor, e)
local nor_e_s = vim.tbl_extend("keep", nor, e, s)

local map = vim.keymap.set

local M = {}
M.go = function()
	map("n", "<leader>llsj", "<cmd> GoTagAdd json <CR>", { desc = "Add json struct tags" })
	map("n", "<leader>llsb", "<cmd> GoTagAdd bson <CR>", { desc = "Add jbson struct tags" })
	map("n", "<leader>lli", "<cmd> GoIfErr <CR>", { desc = "Add if error" })
end
return M
