return {

	{
		"ellisonleao/gruvbox.nvim",
		priority = 1000,
		lazy = false,
		config = function()
			-- vim.g.gruvbox_material_foreground = "original" -- can be material and mix
			vim.o.background = "dark" -- or "light" for light mode
			-- vim.cmd([[
			--     hi clear SpellBad
			--     hi link SpellBad GruvboxRed
			-- ]])
		end,
	},

	{
		"folke/tokyonight.nvim",
		priority = 1000,
		lazy = false,
		branch = "main",
		config = function()
			-- vim.o.background == "dark"
			-- vim.g.tokyonight_style = "storm"
			vim.g.tokyonight_style = "night"
			-- vim.g.tokyonight_sidebars = {"vista_kind"}
			vim.g.tokyonight_sidebars = { "tagbar", "nvim_tree", "netrw" }
			vim.g.tokyonight_lualine_bold = true
			vim.g.tokyonight_transparent = true
			vim.cmd([[ colorscheme tokyonight ]])
		end,
	},

	{
		"catppuccin/nvim",
		priority = 1000,
		lazy = false,
		config = function()
			require("catppuccin").setup({

				flavour = "mocha",
				background = { -- :h background
					light = "latte",
					dark = "mocha",
				},
			})
		end,
	},

	"crusoexia/vim-monokai",
	{
		"rebelot/kanagawa.nvim",
		priority = 1000,
		lazy = false,
	},
	"nyngwang/nvimgelion",
	{
		"hachy/eva01.vim",
		priority = 1000,
		branch = "main",
	},
	"navarasu/onedark.nvim",
}
