vim.api.nvim_create_autocmd("FileType", {
    pattern = "fugitive*",
    callback = function()
        vim.keymap.set("n", "sm", "<cmd>MaximizerToggle<CR>", { buffer = true })
    end,
})
