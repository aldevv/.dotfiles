vim.g.tslime_always_current_session = 1
vim.g.tslime_always_current_window = 1

local open_pane_below = function()
  local idx_tmux = vim.split(vim.fn.system({ "tmux", "display", "-p", "-t", "{down-of}", "#{pane_index}" }), "\n")[1]
  if idx_tmux == "" then
    vim.fn.system({ "tmux", "-f", "~/.config/tmux/tmux.conf", "split-window", "-v", "-p", "40", "-d" })
  end
end

local close_pane_below = function()
  local idx_tmux = vim.split(vim.fn.system({ "tmux", "display", "-p", "-t", "{down-of}", "#{pane_index}" }), "\n")[1]
  if idx_tmux == "" then
    return
  end
  vim.fn.system({ "tmux", "kill-pane", "-t", idx_tmux })
end

local run_cmd = function(idx)
  return function()
    local cmds = require("harpoon").get_term_config().cmds
    open_pane_below()
    if cmds[idx] ~= nil then
      local cmd = cmds[idx]
      cmd = string.gsub(cmd, "'", '"')
      vim.cmd("Tmux " .. cmd)
      return
    end
    vim.print("no command set")
  end
end

vim.keymap.set("n", "ñ ", ":Tmux ")
local maps = { "ñs", "ñt", "ñn", "ñe" }
for i = 1, 4 do
  vim.keymap.set("n", maps[i], run_cmd(i), { desc = "Run command " .. i })
end
vim.keymap.set("n", "ñx", ":Tmux clear<cr>", { desc = "Clear screen", silent = true })

vim.keymap.set("n", "ñc", close_pane_below, { desc = "Close pane", silent = true })
vim.keymap.set("n", "ño", open_pane_below, { desc = "Open pane", silent = true })

vim.api.nvim_create_autocmd("User", {
  pattern = "HarpoonCmdMenu",
  group = vim.api.nvim_create_augroup("tmux_stuff", { clear = true }),
  callback = function()
    vim.print("hello")
    vim.keymap.set("n", "<s-CR>", function()
      vim.print("inside map")
      local line = vim.api.nvim_win_get_cursor(0)[1]
      run_cmd(line)()
      vim.cmd("q")
    end, { remap = true, buffer = true })
  end
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "harpoon",
  callback = function()
    if vim.fn.expand("%") == "harpoon-cmd-menu" then
      vim.cmd("doautocmd User HarpoonCmdMenu")
    end
  end
})