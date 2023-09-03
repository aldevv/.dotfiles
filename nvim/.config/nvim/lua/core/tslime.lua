local run_cmd = function(idx)
  return function()
    local cmds = require("harpoon").get_term_config().cmds
    if cmds[idx] ~= nil then
      vim.cmd("Tmux " .. cmds[idx])
    end
    vim.print("no command set")
  end
end
vim.keymap.set("n", "ñ ", ":Tmux ")
local maps = { "ñs", "ñt", "ñn", "ñe" }
for i = 1, 4 do
  vim.keymap.set("n", maps[i], run_cmd(i), { desc = "Run command " .. i })
end
