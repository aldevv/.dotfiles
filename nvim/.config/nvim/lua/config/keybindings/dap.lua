local M = {}

M.load_mappings = function()
    local s = { silent = true }
    local nor = { noremap = true }
    local nor_s = vim.tbl_extend("keep", nor, s)
    local map = vim.api.nvim_set_keymap

    -- nvim-dap
    map("n", "<leader>cdl", ":lua require'dap'.list_breakpoints()<cr>", nor_s)
    map("n", "<leader>cdb", ":lua require'dap'.toggle_breakpoint()<cr>", nor_s)

    map("n", "<leader>cdBc", ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>", nor_s)
    map("n", "<leader>cdBh", ":lua require'dap'.set_breakpoint(nil, vim.fn.input('Hit count: '))<cr>", nor_s)
    map(
        "n",
        "<leader>cdBl",
        ":lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<cr>",
        nor_s
    )
    map("n", "<leader>cdBe", ":lua require'dap'.set_exception_breakpoints()<cr>", nor_s) -- 'never' | 'always' | 'unhandled' | 'userUnhandled';
    map("n", "<leader>cdBC", ":lua require'dap'.run_to_cursor()<cr>", nor_s)

    -- docs:
    -- h dap.reverse_continue
    map("n", "<leader>cdmt", ":lua require'dap'.terminate{}<cr>", nor_s) -- terminate
    map("n", "<leader>cdmr", ":lua require'dap'.restart()<cr>", nor_s)

    map("n", "<leader>cdu", ":lua require'dap'.up()<cr>", nor_s)
    map("n", "<leader>cdd", ":lua require'dap'.down()<cr>", nor_s)
    map("n", "<leader>cdg", ":lua require'dap'.goto_()<cr>", nor_s) -- not all debuggers support it
    map("n", "<leader>cdh", ":lua require'dap.ui.widgets'.hover()<cr>", nor_s)
    map("n", "<leader>cdp", ":lua require'dap'.pause()<cr>", nor_s)
    map("n", "<leader>cdc", ":lua require'dap'.continue()<cr>", nor_s)
    map("n", "<leader>cdC", ":lua require'dap'.reverse_continue()<cr>", nor_s) -- Continues execution reverse in time until last breakpoint. Debug adapter must support reverse debugging.
    -- map("n", "<leader>cdr", ":lua require'dap'.run()<cr>", nor_s) -- continue already calls this
    map("n", "<leader>cdr", ":lua require'dap'.run_last()<cr>", nor_s)
    map("n", "<leader>cde", ":lua require('utils.lua.dap').eval()<cr>", nor_s)
    map("v", "<leader>cde", ":lua require('dapui').eval()<cr>", nor_s)

    map("n", "<leader>cdn", ":lua require'dap'.step_over()<cr>", nor_s)
    map("n", "<leader>cdsn", ":lua require'dap'.step_over()<cr>", nor_s)
    map("n", "<leader>cdsi", ":lua require'dap'.step_into()<cr>", nor_s)
    map("n", "<leader>cdso", ":lua require'dap'.step_out()<cr>", nor_s)
    map("n", "<leader>cdsb", ":lua require'dap'.step_back()<cr>", nor_s)
end

return M
