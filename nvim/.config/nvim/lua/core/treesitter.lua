--===================
-- TREE SITTER
-- ===================
-- local textobjects = {
--   select = {
--     enable = true,
--
--     -- Automatically jump forward to textobj, similar to targets.vim
--     lookahead = true,
--
--     keymaps = {
--       -- You can use the capture groups defined in textobjects.scm
--       -- ["aa"] = "@parameter.outer",
--       -- ["la"] = "@parameter.inner",
--       ["af"] = "@function.outer",
--       ["lf"] = "@function.inner",
--       ["ac"] = "@class.outer",
--       -- You can optionally set descriptions to the mappings (used in the desc parameter of
--       -- nvim_buf_set_keymap) which plugins like which-key display
--       ["lc"] = { query = "@class.inner", desc = "Select inner part of a class region" },
--       -- You can also use captures from other query groups like `locals.scm`
--       ["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
--     },
--     -- You can choose the select mode (default is charwise 'v')
--     --
--     -- Can also be a function which gets passed a table with the keys
--     -- * query_string: eg '@function.inner'
--     -- * method: eg 'v' or 'o'
--     -- and should return the mode ('v', 'V', or '<c-v>') or a table
--     -- mapping query_strings to modes.
--     selection_modes = {
--       ['@parameter.outer'] = 'v', -- charwise
--       ['@function.outer'] = 'V', -- linewise
--       ['@class.outer'] = '<c-v>', -- blockwise
--     },
--   },
--   move = {
--     enable = true,
--     set_jumps = true,
--
--     goto_next_start = {
--       ["]m"] = "@function.outer",
--       ["]]"] = "@class.outer",
--     },
--     goto_next_end = {
--       ["]M"] = "@function.outer",
--       ["]["] = "@class.outer",
--     },
--     goto_previous_start = {
--       ["[m"] = "@function.outer",
--       ["[["] = "@class.outer",
--     },
--     goto_previous_end = {
--       ["[M"] = "@function.outer",
--       ["[]"] = "@class.outer",
--     },
--     swap = {
--       enable = true,
--       swap_next = {
--         ["<leader>a"] = "@parameter.inner",
--       },
--       swap_previous = {
--         ["<leader>A"] = "@parameter.inner",
--       },
--     },
--   },
-- }
require("nvim-treesitter.configs").setup({
  -- One of "all", "maintained" (parsers with maintainers), or a list of languages
  -- ensure_installed = "all",
  -- textobjects = textobjects,
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
  playground = {
    enable = true,
    disable = {},
    updatetime = 25,         -- Debounced time for highlighting nodes in the playground from source code
    persist_queries = false, -- Whether the query persists across vim sessions
    keybindings = {
      toggle_query_editor = "o",
      toggle_hl_groups = "l",
      toggle_injected_languages = "t",
      toggle_anonymous_nodes = "a",
      toggle_language_display = "L",
      focus_language = "f",
      unfocus_language = "F",
      update = "R",
      goto_node = "<cr>",
      show_help = "?",
    },
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

local ft_to_lang = require("nvim-treesitter.parsers").ft_to_lang
require("nvim-treesitter.parsers").ft_to_lang = function(ft)
  if ft == "zsh" then
    return "bash"
  end
  return ft_to_lang(ft)
end

-- local del_mappings = function()
--   vim.keymap.del("", "if")
--   vim.keymap.del("", "ia")
--   vim.keymap.del("", "ic")
-- end
--
-- local res = pcall(del_mappings)
