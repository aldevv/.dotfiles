-- register zsh ft to use bash
if vim.treesitter.language.register then
	vim.treesitter.language.register("bash", "zsh")
end
local ensure_installed = {
	"vimdoc",
	"bash",
	"python",
	"c",
	"cpp",
	"rust",
	"javascript",
	"typescript",
	"tsx",
	"go",
	"gomod",
	"gosum",
	"gowork",
	"sql",
	"json",
	"dockerfile",
	"make",
	"cmake",
	"markdown",
	"markdown_inline",
	"yaml",
	"http",
	"nix",
	"zig",
	"jsdoc",
	"lua",
	"luadoc",
	"gpg",
	"awk",
	"toml",
	"sxhkdrc",
	"svelte",
	"requirements",
	"prisma",
	"php",
	"phpdoc",
	"ocaml",
	"ocaml_interface",
	"ini",
	"http",
	"html",
	"gitignore",
	"gitcommit",
	"gitattributes",
	"git_rebase",
	"git_config",
	"csv",
	"c_sharp",
	"angular",
}
if os.getenv("NVIM_MINIMAL") ~= nil then
	ensure_installed = {}
end

-- see kickstart.nvim https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua
vim.defer_fn(function()
	require("nvim-treesitter.configs").setup({
		-- One of "all", "maintained" (parsers with maintainers), or a list of languages
		-- ensure_installed = "all",

		-- textobjects sucks because 1. can't add counts to them, 2. bugs for around and inner in
		-- visual mode, not respecting keymap set
		-- textobjects = {
		-- 	select = {
		-- 		enable = true,
		--
		-- 		-- Automatically jump forward to textobj, similar to targets.vim
		-- 		lookahead = true,
		-- 		keymaps = {
		-- 			["af"] = "@function.outer",
		-- 			["lf"] = "@function.inner",
		-- 			["aC"] = "@class.outer",
		-- 			["lC"] = "@class.inner",
		-- 			-- doesnt work well, same with parameters
		-- 			-- ["lc"] = "@comment.inner",
		-- 			-- ["ac"] = "@comment.outer",
		-- 		},
		-- 	},
		-- },
		ensure_installed = ensure_installed,
		-- parser_install_dir = vim.fn.stdpath("data") .. "/treesitter_parsers",
		-- Install languages synchronously (only applied to `ensure_installed`)
		sync_install = true,
		-- List of parsers to ignore installing
		ignore_install = {},
		highlight = {
			-- `false` will disable the whole extension
			enable = true,
			custom_captures = {
				-- Highlight the @foo.bar capture group with the "Identifier" highlight group.
				["foo.bar"] = "Identifier",
			},

			-- list of language that will be disabled
			disable = {},
		},
		indent = {
			enable = true,
			-- disable = { "go" },
			-- disable = { "nix" },
			-- disable = { "yaml", "python" }, -- not working in python as of 23/01/2021
		},
		incremental_selection = {
			enable = true,
			keymaps = {
				-- init_selection = "<c-space>",
				-- node_incremental = "<c-space>",
				-- scope_incremental = "<c-s>",
				-- node_decremental = "<c-backspace>",
			},
		},
		query_linter = {
			enable = true,
			use_virtual_text = true,
			lint_events = { "BufWrite", "CursorHold" },
		},
	})

	local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
	parser_config.markdown.filetype_to_parsername = "octo"
end, 0)
