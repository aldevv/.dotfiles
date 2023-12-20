vim.opt.termguicolors = true
local function req(module)
  return function(name, opts)
    require(module)
  end
  -- return string.format('require("%s")', module)
end

vim.g.mapleader = require("utils.lua.misc").replace_termcodes("<Space>")
-- vim.g.maplocalleader = "\\" -- this is backspace bro don't ask me why
-- vim.keymap.set("n", "<BS>", ":WhichKey <localleader><cr>", { silent = true })

local ok, err = pcall(require, "magick")

return {
  "lewis6991/impatient.nvim",
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    config = req("config.appearance.themes.gruvbox"),
  },

  {
    "stevearc/dressing.nvim",
    config = req("config.appearance.dressing"),
  },
  {
    "rcarriga/nvim-notify",
    config = function()
      require("core.notify")
      vim.notify = require("notify")
    end,
  },
  { "nvim-tree/nvim-web-devicons", lazy = true },
  {
    "nvim-telescope/telescope.nvim",
    version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = req("core.telescope"),
  },

  {
    "folke/tokyonight.nvim",
    branch = "main",
    -- config = req("config.appearance.themes.tokyonight"),
  },
  { "catppuccin/nvim",             config = req("config.appearance.themes.catppuccin") },
  {
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup()
    end
  },
  {
    "ziontee113/color-picker.nvim",
    config = function()
      require("color-picker").setup()
    end
  },
  {
    "nvim-lualine/lualine.nvim",
    config = req("config.appearance.lualine"),
  },

  {
    "neovim/nvim-lspconfig",
    config = req("lsp.lsp"),
    dependencies = {
      { "williamboman/mason.nvim", build = ":MasonUpdate" },
      "williamboman/mason-lspconfig.nvim",
      "folke/neodev.nvim",
      {
        "hrsh7th/nvim-cmp",
        config = req("lsp.cmp"),
        dependencies = {
          "saadparwaiz1/cmp_luasnip",
          "nvim-lua/plenary.nvim",
          "onsails/lspkind-nvim",
          "hrsh7th/cmp-nvim-lsp",
          -- { "hrsh7th/cmp-nvim-lua",   ft = "lua" },
          "hrsh7th/cmp-path",
          "hrsh7th/cmp-buffer",
          "hrsh7th/cmp-cmdline",
          "petertriho/cmp-git",
          { "tzachar/cmp-fuzzy-path", dependencies = "tzachar/fuzzy.nvim" },
        },
      },
    },
  },

  { "simrat39/rust-tools.nvim", lazy = true },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = req("core.treesitter")
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    config = function()
      vim.cmd("hi TreesitterContextLineNumber gui=bold guifg=orange")
    end,
    dependencies = { "nvim-treesitter/nvim-treesitter" }
  },
  {
    "L3MON4D3/LuaSnip",
    config = req("lsp.luasnip"),
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
    end
  },

  {
    -- "jose-elias-alvarez/null-ls.nvim",
    "nvimtools/none-ls.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "williamboman/mason.nvim" },
    config = req("lsp.formatters"),
  },

  "jayp0521/mason-null-ls.nvim",
  {
    "ahmedkhalf/project.nvim",
    config = req("lsp.project"),
  },
  {
    "numToStr/Comment.nvim",
    config = req("core.comment"),
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" } -- better commentstring using treesitter
  },
  {
    "tpope/vim-dispatch",
  },

  {
    "ThePrimeagen/harpoon",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = req("core.harpoon"),
    module = "harpoon",
  },

  {
    "mfussenegger/nvim-dap",
    dependencies = {
      { "rcarriga/nvim-dap-ui",             module = "dapui" },
      { "theHamsta/nvim-dap-virtual-text",  module = "nvim-dap-virtual-text" },
      { "nvim-telescope/telescope-dap.nvim" },
      { "rcarriga/cmp-dap" },
      { "mfussenegger/nvim-dap-python" },
      { "mxsdev/nvim-dap-vscode-js" },
      { "leoluz/nvim-dap-go" },
      "williamboman/mason.nvim",
    },
    -- module = "dap",
    config = req("lsp.dap.dap"),
    module = "dap",
  },

  "jayp0521/mason-nvim-dap.nvim",

  {
    "jbyuki/one-small-step-for-vimkind",
    dependencies = { "mfussenegger/nvim-dap", module = "dap" },
    module = "osv",
  }, -- debug lua files

  {
    "github/copilot.vim",
    init = function()
      vim.cmd([[
        imap <silent><script><expr> <a-y> copilot#Accept("\<a-y>")
        let g:copilot_no_tab_map = v:true
      ]])
      vim.g.copilot_filetypes = { ["*"] = false, rust = true, js = true, ts = true, jsx = true }
      vim.cmd("highlight CopilotSuggestion guifg=#AAAAAA ctermfg=8")
    end,
  },
  "tpope/vim-surround",
  "tpope/vim-repeat",
  {
    "preservim/vim-markdown",
    dependencies = { "godlygeek/tabular" },
  },

  {
    "folke/which-key.nvim",
    config = req("config.appearance.whichkey"),
  },
  {
    "Pocco81/TrueZen.nvim",
    config = req("core.truezen"),
    cmd = { "TZMinimalist", "TZFocus", "TZAtaraxis" },
  },
  {
    "mbbill/undotree",
    cmd = { "UndotreeToggle" },
  },
  {
    "preservim/tagbar",
    init = function()
      vim.g.tagbar_map_closefold = "zc"
      vim.g.tagbar_map_openfold = "zo"
      vim.g.tagbar_show_linenumbers = 2
    end,
    cmd = { "TagbarToggle" },
  },
  {
    "mattn/emmet-vim",
    init = function()
      -- vim.g.user_emmet_install_global = 0
    end,
    config = function()
      vim.keymap.set("i", "€", "<plug>(emmet-expand-abbr)")
    end,
    ft = { "html", "js", "javascriptreact", "typescriptreact", "ts", "css", "vue", "svelte", "jsx", "tsx" },
  },
  {
    "alvan/vim-closetag",
    config = req("core.closetags"),
    ft = { "html", "js", "ts", "css", "vue", "svelte", "jsx", "tsx" },
  },
  {
    "tpope/vim-projectionist",
    dependencies = { "neovim/nvim-lspconfig" },
    config = req("core.projectionist"),
  },

  "tpope/vim-dotenv",

  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = { "tpope/vim-dadbod", "tpope/vim-dotenv", "kristijanhusak/vim-dadbod-completion" },
    config = req("core.dadbod"),
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer", "DBUILastQueryInfo" },
  },
  {
    "ThePrimeagen/vim-be-good",
    cmd = { "VimBeGood" },
  },

  "ThePrimeagen/git-worktree.nvim",
  {
    "lewis6991/gitsigns.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = req("core.gitsigns"),
  },

  "bkad/CamelCaseMotion",
  {
    "szw/vim-maximizer",
    cmd = "MaximizerToggle",
    init = function()
      vim.g.maximizer_set_default_mapping = 0
    end,
  },
  { "osyo-manga/vim-brightest", cmd = "BrightestToggle" },
  { "junegunn/gv.vim",          cmd = "GV" },

  {
    "rbgrouleff/bclose.vim",
    cmd = "Bclose",
    init = function()
      --The :Bclose command deletes a buffer without changing the window layout, unlike :bd.
      vim.g.bclose_no_plugin_maps = 1
    end,
  },
  {
    "tpope/vim-fugitive",
    dependencies = "tpope/vim-rhubarb",
    config = function()
      vim.opt.diffopt = "internal,vertical,closeoff,filler"
    end,
  },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim",
      "vim-test/vim-test",
      "nvim-neotest/neotest-vim-test",
      "nvim-neotest/neotest-go",
      "nvim-neotest/neotest-python",
    },
    config = req("core.neotest"),
    module = "neotest",
  },
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-treesitter/nvim-treesitter" },
    },
    config = req("core.refactoring"),
    module = "refactoring",
  },

  { "Vimjas/vim-python-pep8-indent" }, -- for indentation, treesitter not functional yet 23/01/2022,
  {
    -- this is what you can do
    -- https://nvim-orgmode.github.io/demo.html
    "nvim-orgmode/orgmode",
    config = req("core.org"),
  },
  -- {
  --   "nvim-neorg/neorg",
  --   build = ":Neorg sync-parsers",
  --   dependencies = { "nvim-lua/plenary.nvim" },
  --   config = function()
  --     require("neorg").setup {
  --       load = {
  --         ["core.defaults"] = {},  -- Loads default behaviour
  --         ["core.concealer"] = {}, -- Adds pretty icons to your documents
  --         ["core.dirman"] = {      -- Manages Neorg workspaces
  --           config = {
  --             workspaces = {
  --               notes = "~/.local/share/wiki/notes",
  --             },
  --           },
  --         },
  --       },
  --     }
  --   end,
  -- },

  -- colors
  -- use("dracula/vim")
  "crusoexia/vim-monokai",
  {
    "rebelot/kanagawa.nvim",
    priority = 1000,
    lazy = true,
  },
  "nyngwang/nvimgelion",
  { "hachy/eva01.vim",              priority = 1000, lazy = false },
  {
    "folke/todo-comments.nvim",
    opts = {
      keywords = {
        FIX = {
          icon = " ", -- icon used for the sign, and in search results
          color = "error", -- can be a hex color, or a named color (see below)
          alt = { "FIXME", "BUG", "FIXIT", "ISSUE" }, -- a set of other keywords that all map to this FIX keywords
          -- signs = false, -- configure signs for some keywords individually
        },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = " ", color = "warning", alt = { "ERROR" } },
        WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
        DEPRECATED = { icon = " ", color = "warning", alt = { "DEPRECATED", "XXX" } },
        PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
        NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
        TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
      },
      gui_style = {
        fg = "NONE", -- The gui style to use for the fg highlight group.
        bg = "BOLD", -- The gui style to use for the bg highlight group.
      },
    },
    dependencies = "nvim-lua/plenary.nvim",
  },
  {
    "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    config = function()
      local lsp_lines = require("lsp_lines")
      lsp_lines.setup()
      vim.diagnostic.config({ virtual_lines = false })
      local toggle = function()
        lsp_lines.toggle()
        if vim.diagnostic.config()["virtual_text"] then
          vim.diagnostic.config({ virtual_text = false })
        else
          vim.diagnostic.config({
            virtual_text = { spacing = 2 },
            float = {
              -- source = "if_many",
              source = true,
            },
          })
        end
      end
      vim.keymap.set("", "gO", toggle, { desc = "Toggle lsp_lines" })
    end,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function()
      local M = require("utils.lua.highlight")
      local hooks = require "ibl.hooks"
      hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        vim.api.nvim_set_hl(0, "IndentBlanklineIndent1", { fg = M.colors.dark_red })
        vim.api.nvim_set_hl(0, "IndentBlanklineIndent2", { fg = M.colors.dark_yellow })
        vim.api.nvim_set_hl(0, "IndentBlanklineIndent3", { fg = M.colors.dimm_green })
        vim.api.nvim_set_hl(0, "IndentBlanklineIndent4", { fg = M.colors.dimm_purple })
        vim.api.nvim_set_hl(0, "IndentBlanklineIndent5", { fg = M.colors.white })
        vim.api.nvim_set_hl(0, "IndentBlanklineIndent6", { fg = M.colors.bracket_grey })
        vim.api.nvim_set_hl(0, "IndentBlanklineContextChar", { fg = M.colors.visual_grey })
        vim.api.nvim_set_hl(0, "IndentBlanklineContextStart", { sp = M.colors.dimm_black })
        vim.api.nvim_set_hl(0, "IndentBlanklineContextSpaceChar", {})
        vim.api.nvim_set_hl(0, "Whitespace", { fg = M.colors.cursor_grey })
      end)
      require("ibl").setup({
        indent = {
          highlight = {
            "IndentBlanklineIndent1",
            "IndentBlanklineIndent2",
            "IndentBlanklineIndent3",
            "IndentBlanklineIndent4",
            "IndentBlanklineIndent5",
            "IndentBlanklineIndent6",
          },
          char = "┆"
        },
        whitespace = {
          remove_blankline_trail = true,
        },
      })
    end,
    ft = { "lua", "javascript", "javascriptreact", "typescript" }

  },

  {
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup()
    end,
    cmd = "ToggleTerm",
  },
  {
    "iamcco/markdown-preview.nvim",
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
  },
  {
    "rest-nvim/rest.nvim",
    -- "aldevv/rest.nvim",
    dev = true,
    -- branch = "main",
    dependencies = "nvim-lua/plenary.nvim",
    -- config = req("core.rest"),
  },

  "navarasu/onedark.nvim",
  -- {
  --   "sourcegraph/sg.nvim",
  --   dependencies = { "nvim-lua/plenary.nvim" },
  --   -- opts = { enable_cody = false }
  -- },
  "kana/vim-textobj-user",
  {
    "glts/vim-textobj-comment",
    dependencies = "kana/vim-textobj-user",
    init = function()
      vim.g.textobj_comment_no_default_key_mappings = 1
    end,
  },
  {
    "kana/vim-textobj-entire",
    dependencies = "kana/vim-textobj-user",
    init = function()
      vim.g.textobj_entire_no_default_key_mappings = 1
    end,
  },

  "mkitt/tabline.vim",
  {
    "ray-x/lsp_signature.nvim",
    config = req("lsp.lsp-signature"),
    dependencies = {
      "neovim/nvim-lspconfig",
      "hrsh7th/nvim-cmp",
    },
  },
  {
    "mrcjkb/haskell-tools.nvim",
    config = nil,
    branch = "2.x.x", -- recommended
    lazy = true,
  },
  {
    "BooleanCube/keylab.nvim",
    cmd = "KeylabStart",
    opts = {
      lines = 10,
      force_accuracy = true,
      correct_fg = "#B8BB26",
      wrong_bg = "#FB4934",
    },
  },
  {
    "kevinhwang91/nvim-ufo",
    config = req("core.ufo"),
    dependencies = { "kevinhwang91/promise-async", "nvim-treesitter/nvim-treesitter" },
  },
  {
    "ianding1/leetcode.vim",
    build = "pip3 install keyring browser-cookie3 --user",
    config = function()
      -- Values: 'cpp', 'java', 'python', 'python3', 'csharp', 'javascript', 'ruby', 'swift', 'golang', 'scala', 'kotlin', 'rust'.
      -- Default value is 'cpp'.
      vim.g.leetcode_solution_filetype = "golang"
      vim.g.leetcode_browser = "firefox"
    end,
  },
  -- {
  --     "kawre/leetcode.nvim",
  --     build = ":TSUpdate html",
  --     dependencies = {
  --         "nvim-treesitter/nvim-treesitter",
  --         "nvim-telescope/telescope.nvim",
  --         "nvim-lua/plenary.nvim", -- required by telescope
  --         "MunifTanjim/nui.nvim",
  --
  --         -- optional
  --         "nvim-tree/nvim-web-devicons",
  --
  --         -- recommended
  --         -- "rcarriga/nvim-notify",
  --     },
  --     opts = {
  --         -- configuration goes here
  --     },
  --     config = function(_, opts)
  --         vim.keymap.set("n", "<leader>lq", "<cmd>LcQuestionTabs<cr>")
  --         vim.keymap.set("n", "<leader>lm", "<cmd>LcMenu<cr>")
  --         vim.keymap.set("n", "<leader>lc", "<cmd>LcConsole<cr>")
  --         vim.keymap.set("n", "<leader>ll", "<cmd>LcLanguage<cr>")
  --         vim.keymap.set("n", "<leader>ld", "<cmd>LcDescriptionToggle<cr>")
  --
  --         require("leetcode").setup(opts)
  --     end,
  -- }

  {
    -- if not finding magick rock do these
    -- sudo luarocks install --server=https://luarocks.org/dev luaffi
    -- sudo apt install libmagickwand-dev
    "3rd/image.nvim",
    config = function()
      -- check if luarocks is executable
      if vim.fn.executable("luarocks") == 0 then
        return
      end

      if vim.fn.exists('g:neovide') == 1 then
        return
      end
      require("core.image")
    end,
    ft = "mardown"
  },
  {
    "ekickx/clipboard-image.nvim",
    config = function()
      local curfilepath = vim.fn.expand("%:p:h")
      require 'clipboard-image'.setup({
        -- Default configuration for all filetype
        default = {
          img_dir = curfilepath .. "/.files",
          img_dir_txt = ".files",
          img_name = function() return os.date('%Y-%m-%d-%H-%M-%S') end, -- Example result: "2021-04-13-10-04-18"
          affix =
          "<\n  %s\n>"                                                   -- Multi lines affix
        },
      })
    end
  },
  {
    "stevearc/overseer.nvim",
    config = req("core.overseer")
  },
  {
    "jgdavey/tslime.vim",
    dependencies = "harpoon",
    config = req("core.tslime")
  },
  {
    "ray-x/go.nvim",
    commit = "a8095eb334495caec3099b717cc7f5b1fbc3e628",
    dependencies = { -- optional packages
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("go").setup({
        run_in_floaterm = false,
      })
    end,
    event = { "CmdlineEnter" },
    ft = { "go", 'gomod' },
    build = ':lua require("go.install").update_all_sync()' -- if you need to install/update all binaries
  },
  {
    "windwp/nvim-ts-autotag",
    config = function()
      require('nvim-ts-autotag').setup()
    end
  },
  -- for debugging
  {
    "j-hui/fidget.nvim",
    tag = "legacy",
    event = "LspAttach",
    opts = {
      sources = {
        ["null-ls"] = { ignore = true },
        copilot = { ignore = true }
      }
    },
  }
}
