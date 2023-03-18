-- so these settings are not changed based on filetype
vim.cmd("filetype indent off")

-- use spaces instead of tabs
vim.opt.expandtab = true
-- disabled for treesitter-indent
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.autoindent = false
vim.opt.smartindent = false
