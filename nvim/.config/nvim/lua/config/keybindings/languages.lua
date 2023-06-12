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

local desc = function(desc)
	return vim.tbl_extend("keep", nor_s, { desc = desc })
end

local descv = function(desc)
	return vim.tbl_extend("keep", nor, { desc = desc })
end

local descb = function(desc)
	return vim.tbl_extend("keep", nor, { desc = desc, buffer = true })
end

local M = {}
M.gopls = function()
	map("n", "Esj", "<cmd>GoAddTags json <CR>", { desc = "Add json struct tags" })
	map("n", "Esb", "<cmd>GoAddTags bson <CR>", { desc = "Add jbson struct tags" })
	map("n", "Ei", "<cmd>GoIfErr <CR>", { desc = "Add if error" })
end
return M
