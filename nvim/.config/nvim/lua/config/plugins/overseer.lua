-- transparency
local winblend = 25
local overseer = require("overseer")
overseer.setup({
  templates = { "builtin", "user.run_script" },
  component_aliases = {
    default = {
      -- https://github.com/stevearc/overseer.nvim/blob/master/doc/components.md
      { "display_duration",   detail_level = 2 },
      "on_output_summarize",
      "on_exit_set_status",
      "on_complete_notify",
      -- "on_complete_dispose",
      -- open quickfix by default
      { "on_output_quickfix", open = false },
      -- { "restart_on_save",    delay = 100 },
    },
  },
  task_editor = {
    bindings = {
      i = {
        ["<CR>"] = "Submit",
        ["<Esc>"] = "Cancel",
        ["<a-e>"] = "Prev",
        ["<a-n>"] = "Next",
      },
      n = {
        ["<Esc>"] = "Cancel",
      },
    },
  },
  form = {
    win_opts = {
      winblend = winblend,
    },
  },
  task_win = {
    win_opts = {
      winblend = winblend,
    },
  },
  confirm = {
    win_opts = {
      winblend = winblend,
    },
  },
})

-- open quickfix for all tasks
-- overseer.add_template_hook({
-- dir = "/path/to/my/project",
-- module = "^cargo$",
-- }, function(task_defn, util)
--   util.add_component(task_defn, { "on_output_quickfix", open = true })
-- end)

-- overseer
vim.keymap.set("n", "ñr", ":OverseerRun<cr>", { desc = "Overseer Run", silent = true })
vim.keymap.set("n", "ñxr", ":OverseerQuickAction restart<cr>", { desc = "Overseer Restart", silent = true })
vim.keymap.set("n", "ñxt", ":OverseerQuickAction stop<cr>", { desc = "Overseer Stop", silent = true })
vim.keymap.set("n", "ñw", ":OverseerQuickAction watch<cr>", { desc = "Overseer Watch", silent = true })
vim.keymap.set("n", "ñW", ":OverseerQuickAction unwatch<cr>", { desc = "Overseer Unwatch", silent = true })
vim.keymap.set("n", "ña", ":OverseerQuickAction<cr>", { desc = "Overseer QuickActions", silent = true })
vim.keymap.set("n", "ñp", ":OverseerToggle<cr>", { desc = "Overseer QuickActions", silent = true })

-- vim.keymap.set("n", "SoR",
--   function()
--     local cmd = vim.fn.input("Enter command: ")
--     vim.cmd("OverseerRunCmd " .. cmd)
--   end
--   , { desc = "Overseer Run Cmd" })

vim.keymap.set("n", "ñbs", "<cmd>OverseerSaveBundle<cr>", { desc = "Overseer Save Bundle" })
vim.keymap.set("n", "ñbl", "<cmd>OverseerLoadBundle<cr>", { desc = "Overseer Load Bundle" })
vim.keymap.set("n", "ñbd", "<cmd>OverseerDeleteBundle<cr>", { desc = "Overseer Delete Bundle" })
-- recipes
vim.keymap.set("n", "ñR", "<cmd>OverseerRestartLast<cr>", { desc = "Overseer Delete Bundle" })

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

vim.keymap.set("n", "ñv", OpenVerticalOutput, { desc = "open most recent task output", silent = true })
