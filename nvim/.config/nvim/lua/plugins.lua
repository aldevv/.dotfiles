vim.opt.termguicolors = true
local function req(module)
  return function(name, opts)
    require(module)
  end
end
vim.g.mapleader = require("utils.lua.misc").replace_termcodes("<Space>")
-- vim.g.maplocalleader = "\\" -- this is backspace bro don't ask me why
-- vim.keymap.set("n", "<BS>", ":WhichKey <localleader><cr>", { silent = true })

local ok, err = pcall(require, "magick")

return {
  "lewis6991/impatient.nvim",

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
  {
    "nvim-lualine/lualine.nvim",
    config = req("config.appearance.lualine"),
  },

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
    "ahmedkhalf/project.nvim",
    config = req("lsp.project"),
  },
  {
    "numToStr/Comment.nvim",
    config = req("core.comment"),
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" } -- better commentstring using treesitter
  },
  "tpope/vim-dispatch",
  "tpope/vim-surround",
  "tpope/vim-repeat",
  "mbbill/undotree",

  {
    "github/copilot.vim",
    init = function()
      vim.cmd([[
        let g:copilot_no_tab_map = v:true
        imap <silent><script><expr> <a-y> copilot#Accept("\<a-y>")
      ]])
      vim.g.copilot_filetypes = {
        ["*"] = false,
        lua = true,
        go = true,
        rust = true,
        js = true,
        ts = true,
        jsx = true,
        tsx = true,
        python = true
      }
    end,
  },
  {
    "preservim/vim-markdown",
    dependencies = { "godlygeek/tabular" },
  },

  -- NOTE: delete after a while
  {
    "folke/which-key.nvim",
    config = req("config.appearance.whichkey"),
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
  "bkad/CamelCaseMotion",
  {
    "szw/vim-maximizer",
    cmd = "MaximizerToggle",
    init = function()
      vim.g.maximizer_set_default_mapping = 0
    end,
  },
  { "junegunn/gv.vim",              cmd = "GV" },
  {
    "tpope/vim-fugitive",
    config = function()
      vim.opt.diffopt = "internal,vertical,closeoff,filler"
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = req("core.gitsigns"),
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
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = req("core.harpoon"),
    module = "harpoon",
  },


  { "Vimjas/vim-python-pep8-indent" }, -- for indentation, treesitter not functional yet 23/01/2022,
  {
    -- this is what you can do
    -- https://nvim-orgmode.github.io/demo.html
    "nvim-orgmode/orgmode",
    config = req("core.org"),
  },
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
    dev = true,
    dependencies = "nvim-lua/plenary.nvim",
  },
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
  {
    "stevearc/overseer.nvim",
    config = req("core.overseer")
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
