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
      "on_complete_dispose",
      -- open quickfix by default
      { "on_output_quickfix", open = true },
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
        ["<Esc>"] = "Cancel"
      },
    }
  },
  form = {
    win_opts = {
      winblend = winblend
    }
  },
  task_win = {
    win_opts = {
      winblend = winblend
    }
  },
  confirm = {
    win_opts = {
      winblend = winblend
    }
  },
})

-- open quickfix for all tasks
-- overseer.add_template_hook({
-- dir = "/path/to/my/project",
-- module = "^cargo$",
-- }, function(task_defn, util)
--   util.add_component(task_defn, { "on_output_quickfix", open = true })
-- end)
