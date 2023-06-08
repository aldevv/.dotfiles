vim.opt.termguicolors = true
local function req(module)
	return function(name, opts)
		require(module)
	end
	-- return string.format('require("%s")', module)
end

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

return {

	{
		"neovim/nvim-lspconfig",
		config = req("lsp.lsp"),
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"folke/neodev.nvim",
			{
				"hrsh7th/nvim-cmp",
				config = req("lsp.cmp"),
				dependencies = {
					"saadparwaiz1/cmp_luasnip",
					"nvim-lua/plenary.nvim",
					"onsails/lspkind-nvim",
					"hrsh7th/cmp-nvim-lsp",
					{ "hrsh7th/cmp-nvim-lua", ft = "lua" },
					"hrsh7th/cmp-path",
					"hrsh7th/cmp-buffer",
					"hrsh7th/cmp-cmdline",
					"petertriho/cmp-git",
					-- "saadparwaiz1/cmp_luasnip",
					-- { "quangnguyen30192/cmp-nvim-ultisnips" },
					-- {
					--     "SirVer/ultisnips",
					--     init = function()
					--         vim.g.UltiSnipsNoMap = true
					--         vim.g.UltiSnipsExpandTrigger = "ß"
					--         vim.g.UltiSnipsJumpForwardTrigger = "<a-k>"
					--         vim.g.UltiSnipsJumpBackwardTrigger = "<a-K>"
					--         -- vim.g.UltiSnipsListSnippets = "<c-tab>"
					--         vim.g.UltiSnipsSnippetDirectories = { "my_snippets", "UltiSnips" }
					--     end,
					--     config = function()
					--         require("cmp_nvim_ultisnips.mappings")
					--     end,
					--     dependencies = "quangnguyen30192/cmp-nvim-ultisnips",
					-- },
				},
			},
		},
	},
	{
		"L3MON4D3/LuaSnip",
		-- config = req("lsp.luasnip"),

		config = function()
			require("luasnip").setup({})
			require("luasnip.loaders.from_lua").load({ paths = "~/snippets" })
		end,
		version = "*",
		-- build = "make install_jsregexp",
	},
}
