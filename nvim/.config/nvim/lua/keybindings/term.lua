if pcall(require, "toggleterm") == false then
	return
end

local nor = { noremap = true }
local map = vim.keymap.set

map("n", "sñ", ":botright terminal<cr>", nor)
map({ "n", "t" }, "<a-q>", "<cmd>ToggleTerm direction=float<cr>", nor)

local Terminal = require("toggleterm.terminal").Terminal
local ranger = Terminal:new({
	cmd = "ranger",
	hidden = true,
	direction = "float",
	float_opts = {
		width = function()
			return math.floor(vim.o.columns * 0.7)
		end,
		height = function()
			return math.floor(vim.o.lines * 0.7)
		end,
	},
})
function _ranger_toggle()
	ranger:toggle()
end

map({ "n", "t" }, "<a-Q>", "<cmd>lua _ranger_toggle()<cr>", nor)
map({ "n", "t" }, "<a-1>", "<cmd>ToggleTerm direction=horizontal<cr>", nor)
map({ "n", "t" }, "<a-2>", "<cmd>ToggleTerm direction=vertical size=40<cr>", nor)
map({ "n", "t" }, "<a-3>", "<cmd>ToggleTerm direction=tab<cr>", nor)

map("t", "<a-'>", "<c-\\><c-n>", nor_s)
map("t", "<c-g>", "<c-\\><c-n>gT", nor_s)
map("t", "<c-s-g>", "<c-\\><c-n>gt", nor_s)
