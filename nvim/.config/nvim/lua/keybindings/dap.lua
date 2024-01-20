local M = {}

vim.keymap.set("n", "Sdla", function()
    vim.fn.system "[ ! -d .vscode ] && mkdir .vscode"
    vim.cmd ":e .vscode/launch.json"
end, { desc = "open launch.json" })

M.load_mappings = function(client)
    local s = { silent = true }
    local nor = { noremap = true }
    local nor_s = vim.tbl_extend("keep", nor, s)
    local map = vim.keymap.set

    -- nvim-dap
    -- map("n", "<leader>dl", ":lua require'dap'.list_breakpoints()<cr>", nor_s)
    map("n", "Sdb", ":lua require'dap'.toggle_breakpoint()<cr>", nor_s)

    map("n", "SdBc", ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>", nor_s)
    map("n", "SdBh", ":lua require'dap'.set_breakpoint(nil, vim.fn.input('Hit count: '))<cr>", nor_s)
    map("n", "SdBl", ":lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<cr>", nor_s)
    map("n", "SdBe", ":lua require'dap'.set_exception_breakpoints()<cr>", nor_s) -- 'never' | 'always' | 'unhandled' | 'userUnhandled';
    map("n", "SdBC", ":lua require'dap'.run_to_cursor()<cr>", nor_s)

    -- docs:
    -- h dap.reverse_continue
    map("n", "<F5>", ":lua require'dap'.continue()<cr>", nor_s)
    map("n", "<F10>", ":lua require'dap'.step_over()<cr>", nor_s)
    map("n", "<F11>", ":lua require'dap'.step_into()<cr>", nor_s)
    map("n", "<F12>", ":lua require'dap'.step_out()<cr>", nor_s)

    -- telescope
    map("n", "Sdtc", ":lua require'telescope'.extensions.dap.commands{}<cr>", nor_s)
    map("n", "SdtC", ":lua require'telescope'.extensions.dap.configurations{}<cr>", nor_s)
    map("n", "Sdtl", ":lua require'telescope'.extensions.dap.list_breakpoints{}<cr>", nor_s)
    map("n", "Sdtv", ":lua require'telescope'.extensions.dap.variables{}<cr>", nor_s)
    map("n", "Sdtf", ":lua require'telescope'.extensions.dap.frames{}<cr>", nor_s)

    -- mode
    map("n", "Sdxt", ":lua require'dap'.terminate{}<cr>", nor_s) -- terminate
    map("n", "Sdxr", ":lua require'dap'.restart()<cr>", nor_s)

    -- ooptions
    map("n", "Sdu", ":lua require'dap'.up()<cr>", nor_s)
    map("n", "Sdd", ":lua require'dap'.down()<cr>", nor_s)
    map("n", "Sdg", ":lua require'dap'.goto_()<cr>", nor_s) -- not all debuggers support it
    map("n", "Sdh", ":lua require'dap.ui.widgets'.hover()<cr>", nor_s)
    map("n", "SdP", ":lua require'dap'.pause()<cr>", nor_s)
    map("n", "Sdc", function()
        require("dap.ext.vscode").load_launchjs()
        require("dap").continue()
    end, { desc = "continue (loads launch.json)" })

    map("n", "SdlL", function()
        require("dap.ext.vscode").load_launchjs()
    end, { desc = "loads launch.json" })

    map("n", "SdC", ":lua require'dap'.reverse_continue()<cr>", nor_s) -- Continues execution reverse in time until last breakpoint. Debug adapter must support reverse debugging.
    -- map("n", "Scdr", ":lua require'dap'.run()<cr>", nor_s) -- continue already calls this
    map("n", "Sdr", ":lua require'dap'.run_last()<cr>", nor_s)
    map("n", "Sde", ":lua require('utils.lua.dap').eval()<cr>", nor_s)
    map("v", "Sde", ":lua require('dapui').eval()<cr>", nor_s)

    map("n", "Sdn", ":lua require'dap'.step_over()<cr>", nor_s)
    map("n", "Sdsn", ":lua require'dap'.step_over()<cr>", nor_s)
    map("n", "Sdsi", ":lua require'dap'.step_into()<cr>", nor_s)
    map("n", "Sdso", ":lua require'dap'.step_out()<cr>", nor_s)
    map("n", "Sdsb", ":lua require'dap'.step_back()<cr>", nor_s)

    -- logs

    map("n", "Sdls", ":DapSetLogLevel trace", nor)
    map("n", "Sdll", ":DapShowLog<cr>", nor)

    -- python
    if client == "pyright" then
        map("n", "Edlm", ":lua require('dap-python').test_method()<cr>", nor_s)
        map("n", "Edlc", ":lua require('dap-python').test_class()<cr>", nor_s)
        map("v", "Edls", ":lua require('dap-python').debug_selection()<cr>", nor_s)
    end
    -- go
    if client == "gopls" then
        map("n", "Edt", ":lua require('dap-go').debug_test()<cr>", nor_s)
        map("n", "Edl", ":lua require('dap-go').debug_last_test()<cr>", nor_s)
    end
end

return M
