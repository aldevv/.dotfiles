local s = { silent = true }
local nor = { noremap = true }
local e = { expr = true }
local s_e = vim.tbl_extend("keep", s, e)

local nor_s = vim.tbl_extend("keep", nor, s)
local nor_e = vim.tbl_extend("keep", nor, e)
local nor_e_s = vim.tbl_extend("keep", nor, e, s)

local map = vim.api.nvim_set_keymap

-- it gets deleted for some reason
-- map("x", "lp", "ip", nor_s)
-- map("x", "lw", "iw", nor_s)

map("x", "le", "<Plug>(textobj-entire-i)", s)
map("o", "le", "<Plug>(textobj-entire-i)", s)
map("x", "ae", "<Plug>(textobj-entire-a)", s)
map("o", "ae", "<Plug>(textobj-entire-a)", s)

vim.g.textobj_comment_no_default_key_mappings = 1

map("x", "aC", "<Plug>(textobj-comment-a)", {})
map("o", "aC", "<Plug>(textobj-comment-a)", {})
map("x", "lC", "<Plug>(textobj-comment-i)", {})
map("o", "lC", "<Plug>(textobj-comment-i)", {})
