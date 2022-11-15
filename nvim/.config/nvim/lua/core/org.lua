require("orgmode").setup_ts_grammar()
require("orgmode").setup({
    mappings = {
        org = {
            -- done because original mapping was NOT SILENT
            org_global_cycle = "<ignore>",
        },
    },
})

-- done because original mapping was NOT SILENT
vim.api.nvim_create_autocmd("FileType", {
    pattern = "org",
    callback = function()
        vim.keymap.set(
            "n",
            "<s-tab>",
            '<Cmd>lua require("orgmode").action("org_mappings.global_cycle")<CR>)',
            { silent = true }
        )
    end,
})
