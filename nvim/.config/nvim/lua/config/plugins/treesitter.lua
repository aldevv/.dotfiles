-- register zsh ft to use bash
vim.treesitter.language.register("bash", "zsh")
local ensure_installed = {
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
	"org",
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
}
if os.getenv("NVIM_MINIMAL") ~= "" then
	ensure_installed = {}
end

-- Defer Treesitter setup after first render to improve startup time of 'nvim {filename}'
-- see kickstart.nvim https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua
vim.defer_fn(function()
	require("nvim-treesitter.configs").setup({
		-- One of "all", "maintained" (parsers with maintainers), or a list of languages
		-- ensure_installed = "all",
		-- textobjects = textobjects,
		ensure_installed = ensure_installed,
		-- Install languages synchronously (only applied to `ensure_installed`)
		sync_install = false,
		-- List of parsers to ignore installing
		ignore_install = {},
		highlight = {
			-- `false` will disable the whole extension
			enable = true,
			additional_vim_regex_highlighting = { "org" },
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
			-- disable = { "org", "yaml", "python" }, -- not working in python as of 23/01/2021
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
	-- org mode config
	-- parser_config.org = {
	--     install_info = {
	--         url = "https://github.com/milisims/tree-sitter-org",
	--         revision = "f110024d539e676f25b72b7c80b0fd43c34264ef",
	--         files = { "src/parser.c", "src/scanner.cc" },
	--     },
	--     filetype = "org",
	-- }
end, 0)
