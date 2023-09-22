local wk = require("which-key")
wk.register({
  S = {
    name = "Programming utils",
    d = { name = "DAP" },
    b = { name = "DBUI" },
    r = { name = "RestNvim" },
    t = { name = "NeoTest" },
    o = { name = "Overseer" },
  },
})

-- rest.nvim
vim.keymap.set("n", "Srr", "<Plug>RestNvim<cr>")
vim.keymap.set("n", "Srp", "<Plug>RestNvimPreview<cr>")
vim.keymap.set("n", "Srl", "<Plug>RestNvimLast<cr>")

-- dadbod
-- opening it in a new tab
vim.keymap.set("n", "Sbd", ":tabedit | DBUI<cr>")
vim.keymap.set("n", "SbD", ":DBUIToggle<cr>")
vim.keymap.set("n", "Sba", ":DBUIAddConnection<cr>")
vim.keymap.set("n", "Sbf", ":DBUIFindBuffer<cr>")
vim.keymap.set("n", "Sbq", ":DBUILastQueryInfo<cr>")
-- For queries, filetype is automatically set to sql. Also, two vim.keymap.setpings is added for the sql filetype:
--
-- W - Permanently save query for later use (<Plug>(DBUI_SaveQuery))
-- E - Edit bind parameters (<Plug>(DBUI_EditBindParameters))

vim.keymap.set("n", "Sg", "<cmd>lua require('sg.extensions.telescope').fuzzy_search_results()<CR>",
  { desc = "Sourcegraph search" })

-- overseer
vim.keymap.set("n", "Sor", ":OverseerRun<cr>", { desc = "Overseer Run" })
vim.keymap.set("n", "SoR",
  function()
    local cmd = vim.fn.input("Enter command: ")
    vim.cmd("OverseerRunCmd " .. cmd)
  end
  , { desc = "Overseer Run Cmd" })

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
