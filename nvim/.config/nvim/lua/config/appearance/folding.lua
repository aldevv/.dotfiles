-- =========
-- FOLDING
-- =========
vim.o.foldmethod = "expr"
vim.o.foldexpr = "nvim_treesitter#foldexpr()"
vim.o.foldlevel = 20

vim.api.nvim_create_augroup("remember_folds", {
    clear = true,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
    pattern = "*.*",
    command = "silent! loadview",
    group = "remember_folds",
})

vim.api.nvim_create_autocmd("BufWinLeave", {
    pattern = "*.*",
    command = "mkview",
    group = "remember_folds",
})

-- TODO: fix this so it works with telescope
-- -- for when there are no extensions

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "sh", "zsh", "bash" },
    command = "silent! loadview",
    group = "remember_folds",
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "sh", "zsh", "bash" },
    command = "mkview",
    group = "remember_folds",
})

vim.o.foldenable = true
