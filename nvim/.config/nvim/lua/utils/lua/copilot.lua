local M = {}
vim.g.copilot_no_tab_map = true
vim.b.copilot_enabled = false
vim.api.nvim_set_hl(0, "CopilotSuggestion", { fg = "#9ef87a" })
-- copilot
M.toggle_copilot = function()
  if vim.b.copilot_enabled == true then
    print("Disabling copilot")
    vim.b.copilot_enabled = false
  else
    print("Enabling copilot")
    vim.b.copilot_enabled = true
  end
end
return M
