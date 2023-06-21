local s = { silent = true }
local nor = { noremap = true }
local e = { expr = true }
local s_e = vim.tbl_extend("keep", s, e)

local nor_s = vim.tbl_extend("keep", nor, s)
local nor_e = vim.tbl_extend("keep", nor, e)
local nor_e_s = vim.tbl_extend("keep", nor, e, s)

local map = vim.api.nvim_set_keymap

-- it gets deleted for some reason
map("x", "lp", "ip", nor_s)
map("x", "lw", "iw", nor_s)
map("x", "ll", "<Plug>(textobj-line-i)", s)
map("o", "ll", "<Plug>(textobj-line-i)", s)
map("x", "al", "<Plug>(textobj-line-a)", s)
map("o", "al", "<Plug>(textobj-line-a)", s)

map("x", "le", "<Plug>(textobj-entire-i)", s)
map("o", "le", "<Plug>(textobj-entire-i)", s)
map("x", "ae", "<Plug>(textobj-entire-a)", s)
map("o", "ae", "<Plug>(textobj-entire-a)", s)

-- " python text objects
vim.g.textobj_python_no_default_key_mappings = 1
-- " silent! TextobjPythonDefaultKeyMappings!
-- " af: a function
-- " lf: inner function
-- " ac: a class
-- " lc: inner class
-- " [f previous function
-- " ]f next function
-- " [c previous class
-- " ]c next class

-- vim.cmd([[
-- call textobj#user#map('python', {
--             \   'class': {
--             \     'select-a': '<buffer>ax',
--             \     'select-i': '<buffer>lx',
--             \     'move-n': '<buffer>]x',
--             \     'move-p': '<buffer>[x',
--             \   },
--             \   'function': {
--             \     'select-a': '<buffer>af',
--             \     'select-i': '<buffer>lf',
--             \     'move-n': '<buffer>]f',
--             \     'move-p': '<buffer>[f',
--             \   }
--             \ })
-- ]])
--
-- " text object comments
vim.g.textobj_comment_no_default_key_mappings = 1

map("x", "ac", "<Plug>(textobj-comment-a)", {})
map("o", "ac", "<Plug>(textobj-comment-a)", {})
map("x", "lc", "<Plug>(textobj-comment-i)", {})
map("o", "lc", "<Plug>(textobj-comment-i)", {})
map("x", "aC", "<Plug>(textobj-comment-big-a)", {})
map("o", "aC", "<Plug>(textobj-comment-big-a)", {})
