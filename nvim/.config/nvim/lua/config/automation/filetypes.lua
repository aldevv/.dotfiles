vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern =  "launch.json",
    callback = function()
        -- this combines snippets for launch specific and json filetypes
        vim.cmd("UltiSnipsAddFiletypes launch.json")
        vim.opt.filetype = "launch.json"
        vim.opt.syntax = "json"
    end
})
