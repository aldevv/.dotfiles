local wk = require("which-key")
wk.register({
  S = {
    name = "Programming utils",
    d = { name = "DAP" },
    b = { name = "DBUI" },
    t = { name = "NeoTest" },
    o = { name = "Overseer" },
  },
})

-- neotest
vim.keymap.set("n", "<leader>n", ":lua require('neotest').run.run()<cr>") -- run nearest
vim.keymap.set("n", "<leader>N", ":lua require('neotest').run.run({suite=true})<cr>")

vim.keymap.set("n", "Stp", ":lua require('neotest').output_panel.toggle()<cr>", { desc = "Test: output_panel" })
vim.keymap.set("n", "Stn", ":lua require('neotest').run.run()<cr>")  -- run nearest
vim.keymap.set("n", "Stx", ":lua require('neotest').run.stop()<cr>") -- run nearest
vim.keymap.set("n", "Stf", ":lua require('neotest').run.run(vim.fn.expand('%'))<cr>")
vim.keymap.set("n", "Sts", ":lua require('neotest').summary.toggle()<cr>")
vim.keymap.set("n", "Sto", ":lua require('neotest').output.open({enter = false})<cr>")
vim.keymap.set("n", "StO", ":lua require('neotest').output.open({enter = true})<cr>")
vim.keymap.set("n", "Stl", ":lua require('neotest').run.run_last()<cr>")
vim.keymap.set("n", "Stk", ":lua require('neotest').jump.next({status = 'failed'})<cr>")
vim.keymap.set("n", "StK", ":lua require('neotest').jump.prev({status = 'failed'})<cr>")
vim.keymap.set("n", "Stt", ":lua require('neotest').run.run({suite = true})<cr>")
vim.keymap.set("n", "StS", ":lua require('neotest').run.run({suite = true})<cr>")
vim.keymap.set("n", "Stg", ":TestVisit<cr>")
vim.cmd([[cnoreabbrev Tn TestNearest]])
vim.cmd([[cnoreabbrev Ts TestSuite]])
vim.cmd([[cnoreabbrev Tf TestFile]])
vim.cmd([[cnoreabbrev Tl TestLast]])

-- dadbod
-- opening it in a new tab
vim.keymap.set("n", "Sb", ":tabedit | DBUI<cr>")
vim.keymap.set("n", "SBd", ":DBUIToggle<cr>")
vim.keymap.set("n", "SBa", ":DBUIAddConnection<cr>")
vim.keymap.set("n", "SBf", ":DBUIFindBuffer<cr>")
vim.keymap.set("n", "SBq", ":DBUILastQueryInfo<cr>")
-- For queries, filetype is automatically set to sql. Also, two vim.keymap.setpings is added for the sql filetype:
--
-- W - Permanently save query for later use (<Plug>(DBUI_SaveQuery))
-- E - Edit bind parameters (<Plug>(DBUI_EditBindParameters))

vim.keymap.set(
  "n",
  "Sg",
  "<cmd>lua require('sg.extensions.telescope').fuzzy_search_results()<CR>",
  { desc = "Sourcegraph search" }
)

-- overseer
vim.keymap.set("n", "ñr", ":OverseerRun<cr>", { desc = "Overseer Run", silent = true })
vim.keymap.set("n", "ñxr", ":OverseerQuickAction restart<cr>", { desc = "Overseer Restart", silent = true })
vim.keymap.set("n", "ñxt", ":OverseerQuickAction stop<cr>", { desc = "Overseer Stop", silent = true })
vim.keymap.set("n", "ñw", ":OverseerQuickAction watch<cr>", { desc = "Overseer Watch", silent = true })
vim.keymap.set("n", "ñW", ":OverseerQuickAction unwatch<cr>", { desc = "Overseer Unwatch", silent = true })
vim.keymap.set("n", "ña", ":OverseerQuickAction<cr>", { desc = "Overseer QuickActions", silent = true })
vim.keymap.set("n", "ñp", ":OverseerOpen<cr>", { desc = "Overseer QuickActions", silent = true })

vim.keymap.set("n", "Sor", ":OverseerRun<cr>", { desc = "Overseer Run" })
vim.keymap.set("n", "SoR", ":OverseerQuickAction restart<cr>", { desc = "Overseer Restart" })
vim.keymap.set("n", "Sow", ":OverseerQuickAction watch<cr>", { desc = "Overseer Watch" })
vim.keymap.set("n", "SoW", ":OverseerQuickAction unwatch<cr>", { desc = "Overseer Unwatch" })
-- vim.keymap.set("n", "SoR",
--   function()
--     local cmd = vim.fn.input("Enter command: ")
--     vim.cmd("OverseerRunCmd " .. cmd)
--   end
--   , { desc = "Overseer Run Cmd" })

vim.keymap.set("n", "Sot", "<cmd>OverseerToggle<cr>", { desc = "Overseer Toggle" })
vim.keymap.set("n", "Soa", "<cmd>OverseerQuickAction<cr>", { desc = "Overseer Quick Action" })
vim.keymap.set("n", "Sos", "<cmd>OverseerSaveBundle<cr>", { desc = "Overseer Save Bundle" })
vim.keymap.set("n", "Sol", "<cmd>OverseerLoadBundle<cr>", { desc = "Overseer Load Bundle" })
vim.keymap.set("n", "Sod", "<cmd>OverseerDeleteBundle<cr>", { desc = "Overseer Delete Bundle" })

-- recipes
vim.keymap.set("n", "Soe", "<cmd>OverseerRestartLast<cr>", { desc = "Overseer Delete Bundle" })

vim.api.nvim_create_user_command("OverseerRestartLast", function()
  local overseer = require("overseer")
  local tasks = overseer.list_tasks({ recent_first = true })
  if vim.tbl_isempty(tasks) then
    vim.notify("No tasks found", vim.log.levels.WARN)
  else
    overseer.run_action(tasks[1], "restart")
  end
end, {})

function OpenVerticalOutput()
  local cur_buf = vim.api.nvim_get_current_buf()
  local all_bufs = vim.api.nvim_list_bufs()
  for _, v in ipairs(all_bufs) do
    if vim.fn.getbufvar(v, "&filetype") == "OverseerOutput" then
      vim.cmd("wincmd l")
      vim.cmd('set filetype=""')
      vim.cmd("q")
      return
    end
  end
  vim.cmd("OverseerQuickAction open vsplit")
  local new_buf = vim.api.nvim_get_current_buf()
  if new_buf == cur_buf then
    return
  end
  vim.cmd("set filetype=OverseerOutput")
  vim.cmd("wincmd h")
end

vim.keymap.set("n", "Sov", OpenVerticalOutput, { desc = "open most recent task output", silent = true })

-- cody
vim.keymap.set({ "n", "x" }, "Sc", "<cmd>CodyChat<cr>", { desc = "Cody Chat" })

vim.keymap.set({ "n", "x" }, "SCr", "<cmd>CodyTask<cr>", { desc = "Cody Task perform a task on selected text." })

vim.keymap.set(
  { "n", "x" },
  "SCa",
  "<cmd>CodyAsk<cr>",
  { desc = "CodyAsk Ask a question about the current selection." }
)

vim.keymap.set({ "n", "x" }, "SCt", "<cmd>CodyToggle<cr>", { desc = "CodyToggle" })

vim.keymap.set({ "n", "x" }, "SCn", "<cmd>CodyTaskNext<cr>", { desc = "CodyTaskNext" })

vim.keymap.set({ "n", "x" }, "SCe", "<cmd>CodyTaskPrev<cr>", { desc = "CodyTaskPrev" })

vim.keymap.set({ "n", "x" }, "SCR", "<cmd>CodyRestart<cr>", { desc = "CodyRestart" })
