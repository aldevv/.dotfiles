local M = {}
vim.g.copilot_enabled = false
vim.g.copilot_no_tab_map = true
-- copilot
M.toggle_copilot = function()
    local is_enabled = vim.api.nvim_get_var("copilot_enabled")
    if is_enabled == 1 then
        print("Disabling copilot")
        vim.api.nvim_command("Copilot disable")
    else
        print("Enabling copilot")
        vim.api.nvim_command("Copilot enable")
    end
end
return M
