require("ufo").setup({
	preview = {
		win_config = {
			winblend = 0,
		},
	},
	provider_selector = function(bufnr, filetype, buftype)
		return { "treesitter", "indent" }
	end,
})
