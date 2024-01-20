vim.keymap.set("x", "<leader>rf", function()
	require("refactoring").refactor("Extract Function")
end, { desc = "Extract Function" })
vim.keymap.set("x", "<leader>rF", function()
	require("refactoring").refactor("Extract Function To File")
end, { desc = "Extract Function To File" })
vim.keymap.set("x", "<leader>rv", function()
	require("refactoring").refactor("Extract Variable")
end, { desc = "Extract Variable" })
vim.keymap.set({ "n", "x" }, "<leader>ri", function()
	require("refactoring").refactor("Inline Variable")
end, { desc = "Inline Variable" })

-- Extract block doesn't need visual mode
vim.keymap.set("n", "<leader>rb", function()
	require("refactoring").refactor("Extract Block")
end, { desc = "Extract Block" })
vim.keymap.set("n", "<leader>rB", function()
	require("refactoring").refactor("Extract Block To File")
end, { desc = "Extract Block To File" })

-- You can also use below = true here to to change the position of the printf
-- statement (or set two remaps for either one). This remap must be made in normal mode.
vim.keymap.set("n", "R", function()
	require("refactoring").debug.printf({ below = true })
end, { desc = "Debug Printf" })

-- Print var

vim.keymap.set({ "x", "n" }, "<leader>v", function()
	require("refactoring").debug.print_var({})
end, { desc = "Debug Print Var" })

-- Cleanup function: this remap should be made in normal mode
vim.keymap.set("n", "<leader>rc", function()
	require("refactoring").debug.cleanup({})
end, { desc = "Debug Cleanup" })

-- remap to open the Telescope refactoring menu in visual mode
vim.keymap.set({ "n", "v" }, "<leader>rt", function()
	require("telescope").extensions.refactoring.refactors()
end, { desc = "Telescope Refactors" })
