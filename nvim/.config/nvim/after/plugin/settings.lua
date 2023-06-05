-- so these settings are not changed based on filetype
vim.cmd("filetype indent off")

-- use spaces instead of tabs
vim.opt.expandtab = true
-- disabled for treesitter-indent
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.autoindent = true -- this is the one for when you press "o"
vim.opt.smartindent = false
