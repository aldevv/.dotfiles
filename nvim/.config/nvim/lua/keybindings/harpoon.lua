local M = {}

M.load_mappings = function()
  local s = {
    silent = true,
  }
  local nor = {
    noremap = true,
  }
  local nor_s = vim.tbl_extend("keep", nor, s)
  local map = vim.keymap.set

  local harpoon = require("harpoon")

  map("n", "<c-esc>", function()
    -- harpoon:list():add()
    harpoon:list():append()
  end)
  map("n", "<c-x>", function()
    -- harpoon:list():add()
    harpoon:list():append()
  end)
  map("n", "<C-c>", function()
    harpoon.ui:toggle_quick_menu(harpoon:list())
  end)

  map("n", "<C-s-c>", function()
    harpoon.ui:toggle_quick_menu(harpoon:list("second"))
  end)
  map("n", "ñc", function()
    harpoon.ui:toggle_quick_menu(harpoon:list("command"), { title = "Commands" })
  end, { desc = "harpoon commands" })
  map("n", "ñC", function()
    harpoon.ui:toggle_quick_menu(harpoon:list("test"), { title = "Tests" })
  end, { desc = "harpoon tests" })
  map("n", "Ñc", function()
    harpoon.ui:toggle_quick_menu(harpoon:list("command"), { title = "Tmux Commands" })
  end)
  map("n", "ÑC", function()
    harpoon.ui:toggle_quick_menu(harpoon:list("test"), { title = "Tmux Tests" })
  end)

  map("n", "<C-s-l>", function()
    harpoon.ui:toggle_quick_menu(harpoon:list("Vim Commands"))
  end)

  map("n", "<a-s>", function()
    harpoon:list():select(1)
  end)
  map("n", "<a-t>", function()
    harpoon:list():select(2)
  end)
  map("n", "<a-n>", function()
    harpoon:list():select(3)
  end)
  map("n", "<a-e>", function()
    harpoon:list():select(4)
  end)

  map("n", "<a-s-s>", function()
    harpoon:list("second"):select(1)
  end)
  map("n", "<a-s-t>", function()
    harpoon:list("second"):select(2)
  end)
  map("n", "<a-s-n>", function()
    harpoon:list("second"):select(3)
  end)
  map("n", "<a-s-e>", function()
    harpoon:list("second"):select(4)
  end)

  local run_in_tmux = function(list_name, idx, option)
    if os.getenv("TMUX") == nil then
      harpoon:list(list_name):select(idx)
      return
    end

    local window_name = list_name .. idx
    local window_exists = vim.fn
        .system("tmux list-windows -F '#{window_name}' | grep '^" .. window_name .. "' | wc -l")
        :gsub("\n", "") == "1"

    if not window_exists then
      vim.fn.system("tmux neww -n " .. window_name .. " -d")
    end
    local cmd = harpoon:list(list_name):get(idx).value
    vim.fn.system("tmux send-keys -t '" .. window_name .. "' '" .. cmd .. "' Enter")
    vim.fn.system("tmux select-window -t " .. window_name)
  end

  map("n", "ñs", function()
    harpoon:list("command"):select(1)
  end, { desc = "run harpoon command 1" })
  map("n", "ñt", function()
    harpoon:list("command"):select(2)
  end, { desc = "run harpoon command 2" })
  map("n", "ñn", function()
    harpoon:list("command"):select(3)
  end, { desc = "run harpoon command 3" })
  map("n", "ñe", function()
    harpoon:list("command"):select(4)
  end, { desc = "run harpoon command 4" })

  map("n", "ñS", function()
    harpoon:list("test"):select(1)
  end, { desc = "run harpoon tests 1" })
  map("n", "ñT", function()
    harpoon:list("test"):select(2)
  end, { desc = "run harpoon tests 2" })
  map("n", "ñN", function()
    harpoon:list("test"):select(3)
  end, { desc = "run harpoon tests 3" })
  map("n", "ñE", function()
    harpoon:list("test"):select(4)
  end, { desc = "run harpoon tests 4" })

  -- with tmux
  map("n", "Ñs", function()
    run_in_tmux("command", 1)
  end, { desc = "tmux run harpoon command 1" })
  map("n", "Ñt", function()
    run_in_tmux("command", 2)
  end, { desc = "tmux run harpoon command 2" })
  map("n", "Ñn", function()
    run_in_tmux("command", 3)
  end, { desc = "tmux run harpoon command 3" })
  map("n", "Ñe", function()
    run_in_tmux("command", 4)
  end, { desc = "tmux run harpoon command 4" })

  map("n", "ÑS", function()
    run_in_tmux("test", 1)
  end, { desc = "tmux run harpoon tests 1" })
  map("n", "ÑT", function()
    run_in_tmux("test", 2)
  end, { desc = "tmux run harpoon tests 2" })
  map("n", "ÑN", function()
    run_in_tmux("test", 3)
  end, { desc = "tmux run harpoon tests 3" })
  map("n", "ÑE", function()
    run_in_tmux("test", 4)
  end, { desc = "tmux run harpoon tests 4" })

  -- windows keybindings
  if vim.fn.has("win32") == 1 then
    map("n", "<leader>hh", function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end)

    map("n", "<leader>ha", function()
      -- harpoon:list():add()
      harpoon:list():append()
    end)

    map("n", "<leader>hs", function()
      harpoon:list():select(1)
    end)
    map("n", "<leader>ht", function()
      harpoon:list():select(2)
    end)
    map("n", "<leader>hn", function()
      harpoon:list():select(3)
    end)
    map("n", "<leader>he", function()
      harpoon:list():select(4)
    end)
  end
end

return M
