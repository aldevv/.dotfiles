return {
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			delay = 400,
			triggers = {
				{ "<auto>", mode = "nixsotc" },
				{ "S", mode = { "n", "v" } },
				{ "E", mode = { "n", "v" } },
			},
		},
	},
}
