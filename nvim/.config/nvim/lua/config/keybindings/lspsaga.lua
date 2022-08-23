local M = {}
M.load_mappings = function() -- use these on_attach
    local s = { silent = true }
    local nor = { noremap = true }
    local nor_s = vim.tbl_extend("keep", nor, s)
    local map = vim.keymap.set
    -- lsp
    -- https://rishabhrd.github.io/jekyll/update/2020/09/19/nvim_lsp_config.html

    -- prefix , --> config
    map("n", "<A-q>", "<cmd>Lspsaga open_floaterm<cr>", nor)
    -- map("n", "<leader>lT", ":LspsagaFloaterm echo 'hello world'", nor)

    -- float terminal also you can pass the cli command in open_float_terminal function
end

return M
