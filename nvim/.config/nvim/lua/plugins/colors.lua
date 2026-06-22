return {
	{
		"folke/tokyonight.nvim",
		priority = 10000, -- load before any other plugin so the first render is themed
		lazy = false,
		branch = "main",
		config = function()
			require("tokyonight").setup({
				style = "night",
				transparent = true,
				lualine_bold = true,
				styles = {
					sidebars = "transparent",
					floats = "transparent",
				},
				-- Disable tokyonight's nvim-notify integration. With
				-- transparent=true it would set every NotifyXBody.bg = NONE,
				-- which makes the toast see-through and overrides any
				-- per-buffer NotifyXBody highlight we set later.
				plugins = { notify = false },
				on_highlights = function(hl, c)
					-- sh.vim's shStatement (`alias` kw) and shAlias (the name) both resolve to purple here.
					hl.shAlias = { fg = c.fg }
				end,
			})
			vim.cmd([[ colorscheme tokyonight ]])
		end,
	},

	-- alternates available via :colorscheme. None of these load eagerly anymore.
	{ "ellisonleao/gruvbox.nvim", lazy = true },
	{
		"catppuccin/nvim",
		lazy = true,
		config = function()
			require("catppuccin").setup({
				flavour = "mocha",
				background = { light = "latte", dark = "mocha" },
			})
		end,
	},
	{ "rebelot/kanagawa.nvim", lazy = true },
	{ "crusoexia/vim-monokai", lazy = true },
	{ "nyngwang/nvimgelion", lazy = true },
	{ "hachy/eva01.vim", lazy = true, branch = "main" },
	{ "navarasu/onedark.nvim", lazy = true },
}
