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
    command = "autocmd BufWinEnter * silent! loadview",
    group = "remember_folds",
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "sh", "zsh", "bash" },
    callback = function()
        -- when opening telescope from .zshrc and exiting, it fails if only using
        -- command = "autocmd BufWinLeave * mkview"
        for _, ft in ipairs({ "sh", "zsh", "bash" }) do
            if vim.bo.filetype == ft then
                vim.cmd("autocmd BufWinLeave * mkview")
            end
        end
    end,
    group = "remember_folds",
})

vim.o.foldenable = true
