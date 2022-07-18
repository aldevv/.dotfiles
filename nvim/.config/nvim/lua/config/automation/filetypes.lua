vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "launch.json",
    callback = function()
        -- this combines snippets for launch specific and json filetypes
        vim.cmd("UltiSnipsAddFiletypes launch.json")
        vim.opt.filetype = "launch.json"
        vim.opt.syntax = "json"
    end,
})

vim.api.nvim_create_autocmd({"BufEnter"}, {
    pattern = "*Neotest Summary*",
    callback = function()
        vim.keymap.set("n", "n", "j", { silent = true, buffer = 0 })
        vim.keymap.set("n", "e", "k", { silent = true, buffer = 0 })
        -- vim.keymap.set("n", "<space>", "lua neotest.Config.summary.mappings
    end,
})


