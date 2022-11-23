local M = {}
M.load_mappings = function() -- use these on_attach
    local s = { silent = true }
    local nor = { noremap = true }
    local nor_s = vim.tbl_extend("keep", nor, s)
    local map = vim.keymap.set
    map("n", "<leader>Oo", "<cmd>OverseerRun<cr> | <cmd>OverseerOpen<cr>", nor)
    map("n", "<leader>OO", "<cmd>OverseerRunCmd | <cmd>OverseerOpen<cr>", nor)
    map("n", "<leader>Ot", "<cmd>OverseerToggle<cr>", nor)
    map("n", "<leader>Oq", "<cmd>OverseerQuickAction<cr>", nor)
end

return M
