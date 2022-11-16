local M = {}

M.load_mappings = function()
    local s = { silent = true }
    local nor = { noremap = true }
    local nor_s = vim.tbl_extend("keep", nor, s)
    local map = vim.api.nvim_set_keymap

    -- nvim-dap
    -- map("n", "<leader>dl", ":lua require'dap'.list_breakpoints()<cr>", nor_s)
    map("n", "<localleader>db", ":lua require'dap'.toggle_breakpoint()<cr>", nor_s)

    map("n", "<localleader>dBc", ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>", nor_s)
    map("n", "<localleader>dBh", ":lua require'dap'.set_breakpoint(nil, vim.fn.input('Hit count: '))<cr>", nor_s)
    map(
        "n",
        "<localleader>dBl",
        ":lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<cr>",
        nor_s
    )
    map("n", "<localleader>dBe", ":lua require'dap'.set_exception_breakpoints()<cr>", nor_s) -- 'never' | 'always' | 'unhandled' | 'userUnhandled';
    map("n", "<localleader>dBC", ":lua require'dap'.run_to_cursor()<cr>", nor_s)

    -- docs:
    -- h dap.reverse_continue
    map("n", "<F5>", ":lua require'dap'.continue()<cr>", nor_s)
    map("n", "<F10>", ":lua require'dap'.step_over()<cr>", nor_s)
    map("n", "<F11>", ":lua require'dap'.step_into()<cr>", nor_s)
    map("n", "<F12>", ":lua require'dap'.step_out()<cr>", nor_s)

    -- telescope
    map("n", "<localleader>dtc", ":lua require'telescope'.extensions.dap.commands{}<cr>", nor_s)
    map("n", "<localleader>dtC", ":lua require'telescope'.extensions.dap.configurations{}<cr>", nor_s)
    map("n", "<localleader>dtl", ":lua require'telescope'.extensions.dap.list_breakpoints{}<cr>", nor_s)
    map("n", "<localleader>dtv", ":lua require'telescope'.extensions.dap.variables{}<cr>", nor_s)
    map("n", "<localleader>dtf", ":lua require'telescope'.extensions.dap.frames{}<cr>", nor_s)

    -- mode
    map("n", "<localleader>dxt", ":lua require'dap'.terminate{}<cr>", nor_s) -- terminate
    map("n", "<localleader>dxr", ":lua require'dap'.restart()<cr>", nor_s)
    map("n", "<localleader>dxl", ":lua require'dap.ext.vscode'.load_launchjs()<cr>", nor_s)

    -- ooptions
    map("n", "<localleader>du", ":lua require'dap'.up()<cr>", nor_s)
    map("n", "<localleader>dd", ":lua require'dap'.down()<cr>", nor_s)
    map("n", "<localleader>dg", ":lua require'dap'.goto_()<cr>", nor_s) -- not all debuggers support it
    map("n", "<localleader>dh", ":lua require'dap.ui.widgets'.hover()<cr>", nor_s)
    map("n", "<localleader>dP", ":lua require'dap'.pause()<cr>", nor_s)
    map("n", "<localleader>dc", ":lua require'dap'.continue()<cr>", nor_s)
    map("n", "<localleader>dC", ":lua require'dap'.reverse_continue()<cr>", nor_s) -- Continues execution reverse in time until last breakpoint. Debug adapter must support reverse debugging.
    -- map("n", "<localleader>cdr", ":lua require'dap'.run()<cr>", nor_s) -- continue already calls this
    map("n", "<localleader>dr", ":lua require'dap'.run_last()<cr>", nor_s)
    map("n", "<localleader>de", ":lua require('utils.lua.dap').eval()<cr>", nor_s)
    map("v", "<localleader>de", ":lua require('dapui').eval()<cr>", nor_s)

    map("n", "<localleader>dn", ":lua require'dap'.step_over()<cr>", nor_s)
    map("n", "<localleader>dsn", ":lua require'dap'.step_over()<cr>", nor_s)
    map("n", "<localleader>dsi", ":lua require'dap'.step_into()<cr>", nor_s)
    map("n", "<localleader>dso", ":lua require'dap'.step_out()<cr>", nor_s)
    map("n", "<localleader>dsb", ":lua require'dap'.step_back()<cr>", nor_s)

    -- python
    if vim.bo.filetype == "python" then
        map("n", "<localleader>dlm", ":lua require('dap-python').test_method()<cr>", nor_s)
        map("n", "<localleader>dlc", ":lua require('dap-python').test_class()<cr>", nor_s)
        map("v", "<localleader>dls", ":lua require('dap-python').debug_selection()<cr>", nor_s)
    end
    -- go
    if vim.bo.filetype == "go" then
        map("v", "<localleader>dlt", ":lua require('dap-go').debug_test()<cr>", nor_s)
        map("v", "<localleader>dlm", ":lua require('dap-go').debug_test()<cr>", nor_s)
    end

    -- rust
    if vim.bo.filetype == "rust" then
        map("n", "<localleader>dli", ":RustToggleInlayHints<cr>", nor_s)
        map("n", "<localleader>dlr", ":RustRunnables<cr>", nor_s)
        map("n", "<localleader>dle", ":RustExpandMacro<cr>", nor_s)
        map("n", "<localleader>dlo", ":RustOpenCargo<cr>", nor_s)
        map("n", "<localleader>dlp", ":RustParentModule<cr>", nor_s)
        map("n", "<localleader>dlj", ":RustJoinLines<cr>", nor_s)
        map("n", "<localleader>dlp", ":RustParentModule<cr>", nor_s)
        map("n", "<localleader>dlh", ":RustHoverActions<cr>", nor_s)
        map("v", "<localleader>dlh", ":RustHoverRange<cr>", nor_s)
        map("n", "<localleader>dl<up>", ":RustMoveItemUp<cr>", nor_s)
        map("n", "<localleader>dl<down>", ":RustMoveItemDown<cr>", nor_s)
        map("n", "<localleader>dls", ":RustStartStandaloneServerForBuffer<cr>", nor_s)
        map("n", "<localleader>dld", ":RustDebuggables<cr>", nor_s)
        map("n", "<localleader>dlv", ":RustViewCrateGraph<cr>", nor_s)
        map("n", "<localleader>dlv", ":RustViewCrateGraph<cr>", nor_s)
        map("n", "<localleader>dlR", ":RustReloadWorkspace<cr>", nor_s)
        map("n", "<localleader>dlS", ":RustSSR<cr>", nor_s)
        map("n", "<localleader>dlO", ":RustOpenExternalDocs<cr>", nor_s)
    end
end

return M
