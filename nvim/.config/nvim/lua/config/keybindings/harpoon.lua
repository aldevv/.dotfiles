local M = {}

M.load_mappings = function()
  local s = { silent = true }
  local nor = { noremap = true }
  local nor_s = vim.tbl_extend("keep", nor, s)
  local map = vim.keymap.set

  local harpoon = require("harpoon")

  map("n", "<a-esc>", function() harpoon:list():append() end)
  map("n", "<C-c>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
  map("n", "<C-s-c>", function() harpoon.ui:toggle_quick_menu(harpoon:list("second")) end)
  map("n", "ñc", function() harpoon.ui:toggle_quick_menu(harpoon:list("term"), { title = "commands" }) end)
  map("n", "ñC", function() harpoon.ui:toggle_quick_menu(harpoon:list("tests"), { title = "tests" }) end)
  map("n", "Ñc", function() harpoon.ui:toggle_quick_menu(harpoon:list("term"), { title = "tmux commands" }) end)
  map("n", "ÑC", function() harpoon.ui:toggle_quick_menu(harpoon:list("tests"), { title = "tmux tests" }) end)

  map("n", "<C-s-l>", function() harpoon.ui:toggle_quick_menu(harpoon:list("vimcmd")) end)

  map("n", "<a-s>", function() harpoon:list():select(1) end)
  map("n", "<a-t>", function() harpoon:list():select(2) end)
  map("n", "<a-n>", function() harpoon:list():select(3) end)
  map("n", "<a-e>", function() harpoon:list():select(4) end)

  map("n", "<a-s-s>", function() harpoon:list():select(5) end)
  map("n", "<a-s-t>", function() harpoon:list():select(6) end)
  map("n", "<a-s-n>", function() harpoon:list():select(7) end)
  map("n", "<a-s-e>", function() harpoon:list():select(8) end)

  local run = function(cmd, task_name)
    -- run overseer task based on command
    vim.print(cmd)
    require("overseer").new_task({
      name = "harpoon " .. task_name,
      cmd = cmd,
      components = {
        "on_output_summarize",
        "on_exit_set_status",
        "on_complete_notify",
        {
          'on_output_quickfix',
          open = true
        }, 'default' }
    }):start()
  end


  map("n", "ñs", function() run(harpoon:list("term"):get(1).value, "cmd") end, { desc = "run harpoon command 1" })
  map("n", "ñt", function() run(harpoon:list("term"):get(2).value, "cmd") end, { desc = "run harpoon command 2" })
  map("n", "ñn", function() run(harpoon:list("term"):get(3).value, "cmd") end, { desc = "run harpoon command 3" })
  map("n", "ñe", function() run(harpoon:list("term"):get(4).value, "cmd") end, { desc = "run harpoon command 4" })

  map("n", "ñS", function() run(harpoon:list("tests"):get(1).value, "tests") end, { desc = "run harpoon tests 1" })
  map("n", "ñT", function() run(harpoon:list("tests"):get(2).value, "tests") end, { desc = "run harpoon tests 2" })
  map("n", "ñN", function() run(harpoon:list("tests"):get(3).value, "tests") end, { desc = "run harpoon tests 3" })
  map("n", "ñE", function() run(harpoon:list("tests"):get(4).value, "tests") end, { desc = "run harpoon tests 4" })

  -- with tmux
  map("n", "Ñs", function() harpoon:list("term"):select(1) end, { desc = "run harpoon command 1" })
  map("n", "Ñt", function() harpoon:list("term"):select(2) end, { desc = "run harpoon command 2" })
  map("n", "Ñn", function() harpoon:list("term"):select(3) end, { desc = "run harpoon command 3" })
  map("n", "Ñe", function() harpoon:list("term"):select(4) end, { desc = "run harpoon command 4" })

  map("n", "ÑS", function() harpoon:list("tests"):select(1) end, { desc = "run harpoon tests 1" })
  map("n", "ÑT", function() harpoon:list("tests"):select(2) end, { desc = "run harpoon tests 2" })
  map("n", "ÑN", function() harpoon:list("tests"):select(3) end, { desc = "run harpoon tests 3" })
  map("n", "ÑE", function() harpoon:list("tests"):select(4) end, { desc = "run harpoon tests 4" })
end

return M
