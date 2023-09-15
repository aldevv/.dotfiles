local run_cmd = function(idx)
  return function()
    local cmds = require("harpoon").get_term_config().cmds
    local idx_tmux = vim.split(vim.fn.system({ "tmux", "display", "-p", "-t", "{down-of}", "#{pane_index}" }), "\n")[1]
    if idx_tmux == "" then
      vim.fn.system({ "tmux", "-f", "~/.config/tmux/tmux.conf", "split-window", "-v", "-p", "40", "-d" })
    end

    if cmds[idx] ~= nil then
      vim.cmd("Tmux " .. cmds[idx])
      return
    end
    vim.print("no command set")
  end
end

local close_pane = function()
  local idx_tmux = vim.split(vim.fn.system({ "tmux", "display", "-p", "-t", "{down-of}", "#{pane_index}" }), "\n")[1]
  if idx_tmux == "" then
    return
  end
  vim.fn.system({ "tmux", "kill-pane", "-t", idx_tmux })
end

-- vim.g.tslime_autoset_pane = 1
vim.g.tslime_always_current_session = 1
vim.g.tslime_always_current_window = 1

vim.keymap.set("n", "ñ ", ":Tmux ")
local maps = { "ñs", "ñt", "ñn", "ñe" }
for i = 1, 4 do
  vim.keymap.set("n", maps[i], run_cmd(i), { desc = "Run command " .. i })
end
vim.keymap.set("n", "ñc", ":Tmux clear<cr>", { desc = "Clear screen", silent = true })

vim.keymap.set("n", "ñx", close_pane, { desc = "Close pane", silent = true })
