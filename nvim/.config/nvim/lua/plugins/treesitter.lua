local function req(module)
	return function(name, opts)
		require(module)
	end
end
return {
	{
		"nvim-treesitter/nvim-treesitter",
		priority = 100,
		build = ":TSUpdate",
		config = req("config.plugins.treesitter"),
	},
	{
		-- failing for angular
		"nvim-treesitter/nvim-treesitter-context",
		config = function()
			vim.cmd("hi TreesitterContextLineNumber gui=bold guifg=orange")
		end,
		dependencies = { "nvim-treesitter/nvim-treesitter" },
	},
	"kana/vim-textobj-user",
	{
		"glts/vim-textobj-comment",
		dependencies = "kana/vim-textobj-user",
		init = function()
			vim.g.textobj_comment_no_default_key_mappings = 1
		end,
	},
	{
		"kana/vim-textobj-entire",
		dependencies = "kana/vim-textobj-user",
		init = function()
			vim.g.textobj_entire_no_default_key_mappings = 1
		end,
	},
}
