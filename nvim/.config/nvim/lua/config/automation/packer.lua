vim.cmd([[
    augroup packer_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerCompile
    augroup END
]])
