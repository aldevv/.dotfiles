vim.api.nvim_create_autocmd("FileType", {
    pattern = "fugitive*",
    callback = function()
        vim.keymap.set("n", "sm", "<cmd>MaximizerToggle<CR>", { buffer = true })
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "git*",
    callback = function()
        vim.keymap.set("n", "gq", "<cmd>q<CR>", { buffer = true })
        vim.opt_local.foldmethod = "syntax"
    end,
})
