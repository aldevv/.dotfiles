return {
	{
		"nvim-orgmode/orgmode",
		opts = {

			mappings = {
				text_objects = {
					inner_heading = "<ignore>",
					inner_subtree = "<ignore>",
				},
				org = {
					-- done because original mapping was NOT SILENT
					org_global_cycle = "<ignore>",
					org_cycle = "<ignore>", -- this is tab by default
				},
			},
		},
		event = "VeryLazy",
		ft = { "org" },
		config = function(_, opts)
			require("orgmode").setup(opts)
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "org",
				callback = function()
					vim.keymap.set("n", "<c-i>", "za", { silent = true })
					vim.keymap.set(
						"n",
						"zM",
						'<Cmd>lua require("orgmode").action("org_mappings.global_cycle")<CR>)',
						{ silent = true }
					)
				end,
			})
		end,
	},
}
