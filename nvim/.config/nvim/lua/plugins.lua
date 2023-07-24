vim.opt.termguicolors = true
local function req(module)
  return function(name, opts)
    require(module)
  end
  -- return string.format('require("%s")', module)
end

vim.g.mapleader = require("utils.lua.misc").replace_termcodes("<Space>")
-- NOTE: this won't work till you fix conflicts maps like .v and .vv in the shortcuts script
-- vim.g.maplocalleader = require("utils.lua.misc").replace_termcodes("<BS>") -- this is backspace bro don't ask me why
vim.g.maplocalleader = "\\" -- this is backspace bro don't ask me why
vim.keymap.set("n", "<BS>", ":WhichKey <localleader><cr>", { silent = true })

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
    "axkirillov/easypick.nvim",
    config = req("core.easypick"),
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
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
  -- {
  --   "nvim-treesitter/nvim-treesitter-textobjects",
  --   dependencies = { "nvim-treesitter/nvim-treesitter" },
  -- },
  {
    "nvim-treesitter/nvim-treesitter-context",
    config = function()
      vim.cmd("hi TreesitterContextLineNumber gui=bold guifg=orange")
    end,
    dependencies = { "nvim-treesitter/nvim-treesitter" }
  },
  -- convert to luasnip using
  -- - https://github.com/smjonas/snippet-converter.nvim
  -- and
  -- - https://cj.rs/blog/ultisnips-to-luasnip/
  {
    "L3MON4D3/LuaSnip",
    config = req("lsp.luasnip"),
    -- commit = "*",
  },
  {
    "honza/vim-snippets",
    config = function()
      require("luasnip.loaders.from_snipmate").lazy_load()
    end,
  },
  {
    "rafamadriz/friendly-snippets",
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
      require("luasnip").filetype_extend("all", { "_" })
    end
  },
  {
    "nvimdev/lspsaga.nvim",
    config = req("lsp.lspsaga"),
    event = "LspAttach",
    dependencies = {
      { "nvim-tree/nvim-web-devicons" },
      --Please make sure you install markdown and markdown_inline parser
      { "nvim-treesitter/nvim-treesitter" }
    }
  },

  {
    "jose-elias-alvarez/null-ls.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "williamboman/mason.nvim" },
    config = req("lsp.formatters"),
  },

  "jayp0521/mason-null-ls.nvim",

  {
    "nvim-treesitter/playground",
    dependencies = "nvim-treesitter/nvim-treesitter",
    cmd = { "TSPlaygroundToggle", "TSHighlightCapturesUnderCursor" },
  },
  -- is this needed??? check for haskell
  {
    "ahmedkhalf/project.nvim",
    config = req("lsp.project"),
  },
  {
    "numToStr/Comment.nvim",
    config = req("core.comment"),
  },
  -- {
  --     "echasnovski/mini.comment",
  --     config = function()
  --         require("mini.comment").setup()
  --     end,
  -- },
  --
  -- -- Lazy loading:
  -- -- Load on specific commands
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
      -- { "Pocco81/DAPInstall.nvim", module = "dap-install" },
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
      vim.g.copilot_filetypes = { ["*"] = false, rust = true, js = true, ts = true, jsx = true }
      vim.cmd("highlight CopilotSuggestion guifg=#AAAAAA ctermfg=8")
    end,
  },
  "tpope/vim-surround",
  "tpope/vim-repeat",
  "tommcdo/vim-exchange",
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
  -- --------------------
  {
    "mattn/emmet-vim",
    init = function()
      vim.g.user_emmet_install_global = 0
    end,
    config = function()
      vim.keymap.set("i", "€", "<plug>(emmet-expand-abbr)")
    end,
    ft = { "html", "js", "ts", "css", "vue", "svelte", "jsx", "tsx" },
  },
  {
    "alvan/vim-closetag",
    config = req("core.closetags"),
    ft = { "html", "js", "ts", "css", "vue", "svelte", "jsx", "tsx" },
  },

  {
    "windwp/nvim-autopairs",
    config = req("core.autopairs"),
  },

  {
    "tpope/vim-projectionist",
    dependencies = { "neovim/nvim-lspconfig" },
    config = req("core.projectionist"),
  },

  -- check if there is a file .env
  {
    "tpope/vim-dotenv",
    dependencies = "neovim/nvim-lspconfig",
    cond = function()
      return require("lspconfig.util").root_pattern(".env*")(vim.fn.getcwd()) ~= nil
    end,
  },

  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = { "tpope/vim-dadbod", "tpope/vim-dotenv", "kristijanhusak/vim-dadbod-completion" },
    config = req("core.dadbod"),
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer", "DBUILastQueryInfo" },
  },
  -- fun
  -- broken
  -- { "ThePrimeagen/vim-apm",     cmd = { "VimApm" } },
  {
    "ThePrimeagen/vim-be-good",
    cmd = { "VimBeGood" },
  },
  {
    "ThePrimeagen/git-worktree.nvim",
  },

  {
    "lewis6991/gitsigns.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = req("core.gitsigns"),
  },

  "bkad/CamelCaseMotion",

  {
    "matze/vim-move",
    init = function()
      vim.g.move_key_modifier = "C"
      vim.g.move_map_keys = 0
    end,
  },

  {
    "szw/vim-maximizer",
    cmd = "MaximizerToggle",
    init = function()
      vim.g.maximizer_set_default_mapping = 0
    end,
  },

  -- :h vis commands for visual selection
  "vim-scripts/vis",

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
    "frazrepo/vim-rainbow",
    cmd = "RainbowToggle",
    init = function()
      vim.g.rainbow_active = 0
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
  { "brooth/far.vim",               cmd = { "Far", "Fardo", "Farr" } },

  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-treesitter/nvim-treesitter" },
    },
    config = req("core.refactoring"),
    module = "refactoring",
  },

  {
    "pwntester/octo.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = { default_remote = { "origin", "upstream" } },
  },

  { "Vimjas/vim-python-pep8-indent" }, -- for indentation, treesitter not functional yet 23/01/202,
  {
    -- this is what you can do
    -- https://nvim-orgmode.github.io/demo.html
    "nvim-orgmode/orgmode",
    config = req("core.org"),
  },

  -- colors
  -- use("dracula/vim")
  "crusoexia/vim-monokai",
  -- NOTE: do the lazy and priority following docs
  {
    "rebelot/kanagawa.nvim",
    priority = 1000,
    lazy = true,
  },
  "nyngwang/nvimgelion",
  { "hachy/eva01.vim", priority = 1000, lazy = false },
  {
    "folke/todo-comments.nvim",
    opts = {
      keywords = {
        FIX = {
          icon = " ",                              -- icon used for the sign, and in search results
          color = "error",                            -- can be a hex color, or a named color (see below)
          alt = { "FIXME", "BUG", "FIXIT", "ISSUE" }, -- a set of other keywords that all map to this FIX keywords
          -- signs = false, -- configure signs for some keywords individually
        },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = " ", color = "warning", alt = { "ERROR" } },
        WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
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

  -- use({ "anuvyklack/hydra.nvim", config = req("core.hydra") })
  -- prettier lsp
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

  -- TODO: test this
  -- use("smolovk/projector.nvim")

  -- TODO: test this to have custom themes per project
  -- https://muniftanjim.dev/blog/neovim-project-local-config-with-exrc-nvim/
  -- use("MunifTanjim/exrc.nvim")
  -- "phaazon/mind.nvim",
  {
    "lukas-reineke/indent-blankline.nvim",
    init = function()
      vim.g.indentLine_char = "┆"
      vim.g.indent_blankline_enabled = true
      vim.g.indent_blankline_filetype = { "lua", "javascript", "typescript" }
      local M = require("utils.lua.highlight")
      M.highlight("IndentBlanklineIndent1", { fg = M.colors.dark_red, gui = "nocombine" })
      M.highlight("IndentBlanklineIndent2", { fg = M.colors.dark_yellow, gui = "nocombine" })
      M.highlight("IndentBlanklineIndent3", { fg = M.colors.dimm_green, gui = "nocombine" })
      M.highlight("IndentBlanklineIndent4", { fg = M.colors.dimm_purple, gui = "nocombine" })
      M.highlight("IndentBlanklineIndent5", { fg = M.colors.white, gui = "nocombine" })
      M.highlight("IndentBlanklineIndent6", { fg = M.colors.bracket_grey, gui = "nocombine" })
      M.highlight("IndentBlanklineContextChar", { fg = M.colors.visual_grey, gui = "nocombine" })
      M.highlight("IndentBlanklineContextStart", { sp = M.colors.dimm_black, gui = "underline" })
      M.highlight("IndentBlanklineContextSpaceChar", { gui = "nocombine" })
      M.highlight("Whitespace", { fg = M.colors.cursor_grey })
    end,
    opts = {
      show_end_of_line = true,
      space_char_blankline = " ",
      show_current_context = true,
      show_current_context_start = false,
      char_highlight_list = {
        "IndentBlanklineIndent1",
        "IndentBlanklineIndent2",
        "IndentBlanklineIndent3",
        "IndentBlanklineIndent4",
        "IndentBlanklineIndent5",
        "IndentBlanklineIndent6",
      },
    },
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

  -- https://github.com/nvim-telescope/telescope-media-files.nvim
  -- for better go experience
  -- https://github.com/ray-x/go.nvim
  "navarasu/onedark.nvim",
  -- {
  --   "sourcegraph/sg.nvim",
  --   dependencies = { "nvim-lua/plenary.nvim" },
  --   -- If you have a recent version of lazy.nvim, you don't need to add this!
  --   -- build = "nvim -l build/init.lua",
  -- },
  -- {
  --
  --   "sourcegraph/cody.nvim",
  --   config = function()
  --     require("cody").setup({
  --       accessToken = "access token",
  --       -- OPTIONAL:
  --       -- url = "https://your-sourcegraph-instance.com"
  --     })
  --   end,
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
    branch = "1.x.x", -- recommended
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
  -- {
  --   "olexsmir/gopher.nvim",
  --   -- ft = "go",
  --   config = function(_, opts)
  --     require("gopher").setup(opts)
  --   end,
  --   build = ":GoInstallDeps",
  -- },
  {
    "kevinhwang91/nvim-ufo",
    config = req("core.ufo"),
    dependencies = { "kevinhwang91/promise-async", "nvim-treesitter/nvim-treesitter" },
  },
  {
    "wellle/targets.vim",
    init = function()
      vim.g.targets_aiAI = { "a", "l", "A", "L" }
      vim.g.targets_mapped_aiAI = { "a", "i", "A", "I" }
      vim.g.targets_nl = { "n", "N" }
      -- this script lets you apply macros to multiple lines
      -- vim.cmd("source ~/.config/nvim/modules/visual-at.vim")
    end,
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
  -- NOTE: failing for gUlw
  -- { 'echasnovski/mini.nvim', version = '*', config = function()
  --   require("mini.ai").setup({
  --     mappings = {
  --       inside = "l",
  --       inside_next = "ln",
  --       inside_last = "ll"
  --     }
  --   })
  -- end
  -- },

  -- {
  --   "folke/persistence.nvim",
  --   event = "BufReadPre", -- this will only start session saving when an actual file was opened
  --   opts = {
  --     dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/"), -- directory where session files are saved
  --     options = { "buffers", "curdir", "tabpages", "winsize" }, -- sessionoptions used for saving
  --     pre_save = nil, -- a function to call before saving the session
  --   }
  -- }
  -- {
  -- 	"napisani/nvim-github-codesearch",
  -- 	build = "make",
  -- 	config = function()
  -- 		-- dependency: apt-get install libluajit-5.1-dev
  -- 		local f = io.open(vim.env.HOME .. "/.config/tokens/tokens.json", "r")
  -- 		if not f then
  -- 			return
  -- 		end
  -- 		local contents = f:read("*all")
  -- 		local decoded = vim.json.decode(contents)
  -- 		require("nvim-github-codesearch").setup({
  -- 			github_auth_token = decoded["GITHUB_TOKEN"],
  -- 		})
  -- 		f.close()
  -- 	end,
  -- },
  -- "prisma/vim-prisma",
  -- looks good, have to pay
  -- {
  --     "Bryley/neoai.nvim",
  --     dependencies = {
  --         "MunifTanjim/nui.nvim",
  --     },
  --     cmd = {
  --         "NeoAI",
  --         "NeoAIOpen",
  --         "NeoAIClose",
  --         "NeoAIToggle",
  --         "NeoAIContext",
  --         "NeoAIContextOpen",
  --         "NeoAIContextClose",
  --         "NeoAIInject",
  --         "NeoAIInjectCode",
  --         "NeoAIInjectContext",
  --         "NeoAIInjectContextCode",
  --     },
  --     keys = {
  --         { "<leader>as", desc = "summarize text" },
  --         { "<leader>ag", desc = "generate git message" },
  --     },
  --     config = function()
  --         require("neoai").setup({
  --             -- Options go here
  --         })
  --     end,
  -- },
  -- "rawnly/gist.nvim", -- getting error when CreateGist
  -- {
  --     "miversen33/netman.nvim",
  --     config = function()
  --         require("netman")
  --     end,
  -- },
  -- {
  --     "esensar/nvim-dev-container",
  --     config = function()
  --         require("devcontainer").setup({})
  --     end,
  --     dependencies = "nvim-treesitter/nvim-treesitter",
  -- },
  -- {
  --     "jamestthompson3/nvim-remote-containers",
  --     config = function()
  --             vim.cmd([[
  --             hi Container guifg=#BADA55 guibg=Black
  --             set statusline+=%#Container#%{g:currentContainer}
  --             ]])
  --     end,
  -- },

  -- unstable 02/03/2023
  -- {
  --     "stevearc/oil.nvim",
  --     init = function()
  --         -- avoid loading netrw
  --         vim.g.loaded_netrw = 1
  --         vim.g.loaded_netrwPlugin = 1
  --
  --         vim.keymap.set("n", "ss", "<cmd>silent Oil<cr>", { silent = true })
  --         vim.keymap.set("n", "sS", "<cmd>silent Oil .<cr>", { silent = true })
  --         vim.keymap.set("n", "st", "<cmd>silent tabnew | Oil<cr>", { silent = true })
  --         vim.keymap.set("n", "sT", "<cmd>silent tabnew | Oil .<cr>", { silent = true })
  --         vim.keymap.set("n", "sv", "<cmd>silent topleft vs | vertical resize 35 | Oil<cr>", { silent = true })
  --         vim.keymap.set("n", "sV", "<cmd>silent topleft vs | vertical resize 35 | Oil .<cr>", { silent = true })
  --     end,
  --     config = req("core.oil"),
  -- },

  -- need to pay lol
  -- {
  --     "jackMort/ChatGPT.nvim",
  --     config = req("core.chatgpt"),
  --     dependencies = {
  --         "MunifTanjim/nui.nvim",
  --         "nvim-lua/plenary.nvim",
  --         "nvim-telescope/telescope.nvim",
  --     },
  -- },
  -- {
  --     "j-hui/fidget.nvim",
  --     config = function()
  --         require("fidget").setup({})
  --     end,
  -- },

  -- too heavy
  {
    "ray-x/go.nvim",
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
  }

  -- enable when dadbod completion stops working
  -- use("nanotee/sqls.nvim")

  -- use({
  --     "stevearc/overseer.nvim",
  --     config = req("core.overseer"),
  --     dependencies = {
  --         "stevearc/dressing.nvim",
  --         "nvim-telescope/telescope.nvim",
  --         "rcarriga/nvim-notify",
  --     },
  --     cmd = { "Overseerbuild", "OverseerbuildCmd", "OverseerToggle", "OverseerQuickAction" },
  -- })

  -- check arpeggio https://github.com/kana/vim-arpeggio
  -- check sideways https://github.com/AndrewRadev/sideways.vim

  -- not working with sshconfig as of 13 jan 2021
  -- use({
  --     "chipsenkbeil/distant.nvim",
  --     branch = "v0.2",
  --     config = function()
  --         require("distant").setup({
  --             -- Applies Chip's personal settings to every machine you connect to
  --             --
  --             -- 1. Ensures that distant servers terminate with no connections
  --             -- 2. Provides navigation bindings for remote directories
  --             -- 3. Provides keybinding to jump into a remote file's parent directory
  --             ["*"] = require("distant.settings").chip_default(),
  --         })
  --     end,
  -- }),
}
