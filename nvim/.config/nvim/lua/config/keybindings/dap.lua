local M = {}

M.load_mappings = function(client)
  local s = { silent = true }
  local nor = { noremap = true }
  local nor_s = vim.tbl_extend("keep", nor, s)
  local map = vim.api.nvim_set_keymap

  -- nvim-dap
  -- map("n", "<leader>dl", ":lua require'dap'.list_breakpoints()<cr>", nor_s)
  map("n", "<Del>db", ":lua require'dap'.toggle_breakpoint()<cr>", nor_s)

  map("n", "<Del>dBc", ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>", nor_s)
  map("n", "<Del>dBh", ":lua require'dap'.set_breakpoint(nil, vim.fn.input('Hit count: '))<cr>", nor_s)
  map(
    "n",
    "<Del>dBl",
    ":lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<cr>",
    nor_s
  )
  map("n", "<Del>dBe", ":lua require'dap'.set_exception_breakpoints()<cr>", nor_s) -- 'never' | 'always' | 'unhandled' | 'userUnhandled';
  map("n", "<Del>dBC", ":lua require'dap'.run_to_cursor()<cr>", nor_s)

  -- docs:
  -- h dap.reverse_continue
  map("n", "<F5>", ":lua require'dap'.continue()<cr>", nor_s)
  map("n", "<F10>", ":lua require'dap'.step_over()<cr>", nor_s)
  map("n", "<F11>", ":lua require'dap'.step_into()<cr>", nor_s)
  map("n", "<F12>", ":lua require'dap'.step_out()<cr>", nor_s)

  -- telescope
  map("n", "<Del>dtc", ":lua require'telescope'.extensions.dap.commands{}<cr>", nor_s)
  map("n", "<Del>dtC", ":lua require'telescope'.extensions.dap.configurations{}<cr>", nor_s)
  map("n", "<Del>dtl", ":lua require'telescope'.extensions.dap.list_breakpoints{}<cr>", nor_s)
  map("n", "<Del>dtv", ":lua require'telescope'.extensions.dap.variables{}<cr>", nor_s)
  map("n", "<Del>dtf", ":lua require'telescope'.extensions.dap.frames{}<cr>", nor_s)

  -- mode
  map("n", "<Del>dxt", ":lua require'dap'.terminate{}<cr>", nor_s) -- terminate
  map("n", "<Del>dxr", ":lua require'dap'.restart()<cr>", nor_s)
  map("n", "<Del>dxl", ":lua require'dap.ext.vscode'.load_launchjs()<cr>", nor_s)

  -- ooptions
  map("n", "<Del>du", ":lua require'dap'.up()<cr>", nor_s)
  map("n", "<Del>dd", ":lua require'dap'.down()<cr>", nor_s)
  map("n", "<Del>dg", ":lua require'dap'.goto_()<cr>", nor_s) -- not all debuggers support it
  map("n", "<Del>dh", ":lua require'dap.ui.widgets'.hover()<cr>", nor_s)
  map("n", "<Del>dP", ":lua require'dap'.pause()<cr>", nor_s)
  map("n", "<Del>dc", ":lua require'dap'.continue()<cr>", nor_s)
  map("n", "<Del>dC", ":lua require'dap'.reverse_continue()<cr>", nor_s) -- Continues execution reverse in time until last breakpoint. Debug adapter must support reverse debugging.
  -- map("n", "<Del>cdr", ":lua require'dap'.run()<cr>", nor_s) -- continue already calls this
  map("n", "<Del>dr", ":lua require'dap'.run_last()<cr>", nor_s)
  map("n", "<Del>de", ":lua require('utils.lua.dap').eval()<cr>", nor_s)
  map("v", "<Del>de", ":lua require('dapui').eval()<cr>", nor_s)

  map("n", "<Del>dn", ":lua require'dap'.step_over()<cr>", nor_s)
  map("n", "<Del>dsn", ":lua require'dap'.step_over()<cr>", nor_s)
  map("n", "<Del>dsi", ":lua require'dap'.step_into()<cr>", nor_s)
  map("n", "<Del>dso", ":lua require'dap'.step_out()<cr>", nor_s)
  map("n", "<Del>dsb", ":lua require'dap'.step_back()<cr>", nor_s)

  -- logs

  map("n", "<Del>dls", ":DapSetLogLevel trace", nor)
  map("n", "<Del>dll", ":DapShowLog<cr>", nor)

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
