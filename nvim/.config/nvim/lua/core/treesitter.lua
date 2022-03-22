--===================
-- TREE SITTER
-- ===================

require("nvim-treesitter.configs").setup({
    -- One of "all", "maintained" (parsers with maintainers), or a list of languages
    -- ensure_installed = "all",
    ensure_installed = "maintained",

    -- Install languages synchronously (only applied to `ensure_installed`)
    sync_install = false,

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
        disable = { "org" },

        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        additional_vim_regex_highlighting = false,
    },
    indent = {
        enable = true,
        disable = { "yaml", "python" }, -- not working in python as of 23/01/2021
    },
    incremental_selection = {
        enable = true,
        keymaps = {
            init_selection = "gN",
            node_incremental = "grn",
            scope_incremental = "grs",
            node_decremental = "grd",
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
parser_config.org = {
    install_info = {
        url = "https://github.com/milisims/tree-sitter-org",
        revision = "f110024d539e676f25b72b7c80b0fd43c34264ef",
        files = { "src/parser.c", "src/scanner.cc" },
    },
    filetype = "org",
}
parser_config.markdown.used_by = "octo"
