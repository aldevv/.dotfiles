local function req(module)
	return function(name, opts)
		require(module)
	end
	-- return string.format('require("%s")', module)
end
return {

	{
		"L3MON4D3/LuaSnip",
		config = req("config.plugins.luasnip"),
	},
	{
		"honza/vim-snippets",
		config = function()
			require("luasnip.loaders.from_snipmate").lazy_load({ exclude = { "javascript", "typescript" } })
		end,
	},
	{
		"rafamadriz/friendly-snippets",
		config = function()
			-- require("luasnip.loaders.from_vscode").lazy_load({ exclude = { "javascript", "typescript" } })
			require("luasnip.loaders.from_vscode").lazy_load()
			require("luasnip").filetype_extend("all", { "_" })
		end,
	},
}
