local M = {}
M.load_mappings = function() -- use these on_attach
    local s = { silent = true }
    local nor = { noremap = true }
    local nor_s = vim.tbl_extend("keep", nor, s)
    local map = vim.keymap.set
    -- lsp
    -- https://rishabhrd.github.io/jekyll/update/2020/09/19/nvim_lsp_config.html
end

return M
