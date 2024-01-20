local M = {}
M.toggle_copilot = function()
	if vim.g.copilot_enabled == true then
		print("Disabling copilot")
		vim.g.copilot_enabled = false
	else
		print("Enabling copilot")
		vim.g.copilot_enabled = true
	end
end
return M
