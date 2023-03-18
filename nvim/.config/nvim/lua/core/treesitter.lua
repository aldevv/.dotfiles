--===================
-- TREE SITTER
-- ===================

require("nvim-treesitter.configs").setup({
    -- One of "all", "maintained" (parsers with maintainers), or a list of languages
    -- ensure_installed = "all",
    ensure_installed = {
        "python",
        "c",
        "cpp",
        "rust",
        "javascript",
        "typescript",
        "tsx",
        "bash",
        "go",
        "sql",
        "json",
        "dockerfile",
        "cmake",
        "markdown",
        "markdown_inline",
        "make",
        "yaml",
        "org",
        "http",
        "nix",
    },
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

        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
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
            init_selection = "<c-space>",
            node_incremental = "<c-space>",
            scope_incremental = "<c-s>",
            node_decremental = "<c-backspace>",
        },
    },
    textobjects = {
        select = {
            enable = true,
            lookahead = true,
            keymaps = {
                ["aa"] = "@parameter.outer",
                ["la"] = "@parameter.inner",
                ["am"] = "@function.outer",
                ["lm"] = "@function.inner",
                ["ac"] = "@class.outer",
                ["lc"] = "@class.inner",
            },
        },
    },
    move = {
        enable = true,
        set_jumps = true,

        goto_next_start = {
            ["]m"] = "@function.outer",
            ["]]"] = "@class.outer",
        },
        goto_next_end = {
            ["]M"] = "@function.outer",
            ["]["] = "@class.outer",
        },
        goto_previous_start = {
            ["[m"] = "@function.outer",
            ["[["] = "@class.outer",
        },
        goto_previous_end = {
            ["[M"] = "@function.outer",
            ["[]"] = "@class.outer",
        },
        swap = {
            enable = true,
            swap_next = {
                ["<leader>a"] = "@parameter.inner",
            },
            swap_previous = {
                ["<leader>A"] = "@parameter.inner",
            },
        },
    },
    playground = {
        enable = true,
        disable = {},
        updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
        persist_queries = false, -- Whether the query persists across vim sessions
        keybindings = {
            toggle_query_editor = "o",
            toggle_hl_groups = "i",
            toggle_injected_languages = "t",
            toggle_anonymous_nodes = "a",
            toggle_language_display = "I",
            focus_language = "f",
            unfocus_language = "F",
            update = "R",
            goto_node = "<cr>",
            show_help = "?",
        },
    },
})

local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
-- org mode config
-- parser_config.org = {
--     install_info = {
--         url = "https://github.com/milisims/tree-sitter-org",
--         revision = "f110024d539e676f25b72b7c80b0fd43c34264ef",
--         files = { "src/parser.c", "src/scanner.cc" },
--     },
--     filetype = "org",
-- }
parser_config.markdown.filetype_to_parsername = "octo"

local ft_to_lang = require("nvim-treesitter.parsers").ft_to_lang
require("nvim-treesitter.parsers").ft_to_lang = function(ft)
    if ft == "zsh" then
        return "bash"
    end
    return ft_to_lang(ft)
end
