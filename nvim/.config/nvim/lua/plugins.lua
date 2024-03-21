vim.opt.termguicolors = true
local function req(module)
  return function(name, opts)
    require(module)
  end
end
vim.g.mapleader = require("utils.lua.misc").replace_termcodes("<Space>")
-- vim.g.maplocalleader = "\\" -- this is backspace bro don't ask me why
-- vim.keymap.set("n", "<BS>", ":WhichKey <localleader><cr>", { silent = true })

return {
  "tpope/vim-dispatch",
  "tpope/vim-dotenv",
  "tpope/vim-surround",
  "tpope/vim-repeat",
  "mbbill/undotree",
  "bkad/CamelCaseMotion",
  "nvim-tree/nvim-web-devicons",
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = req("config.plugins.harpoon"),
  },
  {
    "kevinhwang91/nvim-ufo",
    config = req("config.plugins.ufo"),
    dependencies = { "kevinhwang91/promise-async", "nvim-treesitter/nvim-treesitter" },
  },
  {
    "stevearc/overseer.nvim",
    config = req("config.plugins.overseer"),
  },
  {
    "ahmedkhalf/project.nvim",
    config = req("config.plugins.project"),
  },
  {
    "szw/vim-maximizer",
    cmd = "MaximizerToggle",
    init = function()
      vim.g.maximizer_set_default_mapping = 0
    end,
  },
  {
    "numToStr/Comment.nvim",
    config = req("config.plugins.comment"),
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" }, -- better commentstring using treesitter
  },
  {
    "github/copilot.vim",
    init = function()
      vim.cmd([[
        let g:copilot_no_tab_map = v:true
        imap <silent><script><expr> <a-y> copilot#Accept("\<a-y>")
      ]])
      vim.g.copilot_filetypes = {
        ["*"] = true,
        ["txt"] = false,
        ["md"] = false,
        [""] = false,
        -- ["docker-compose"] = true,
        -- dockerfile = true,
        -- json = true,
        -- yaml = true,
        -- sh = true,
        -- lua = true,
        -- go = true,
        -- rust = true,
        -- js = true,
        -- ts = true,
        -- jsx = true,
        -- tsx = true,
        -- python = true,
      }
    end,
  },

  -- optional
  {
    "iamcco/markdown-preview.nvim",
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
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
    "folke/which-key.nvim",
    config = req("config.plugins.whichkey"),
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = { "tpope/vim-dadbod", "tpope/vim-dotenv", "kristijanhusak/vim-dadbod-completion" },
    config = req("config.plugins.dadbod"),
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer", "DBUILastQueryInfo" },
  },
  {
    "ThePrimeagen/vim-be-good",
    cmd = { "VimBeGood" },
  },
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-treesitter/nvim-treesitter" },
    },
    config = req("config.plugins.refactoring"),
  },
  {
    "nvim-orgmode/orgmode",
    -- this version doesn't want to run 21/03/2024
    -- commit = "ab045e3", -- v0.3.
    commit = "93ab75f",
    dependencies = {
      { "nvim-treesitter/nvim-treesitter", lazy = true },
    },
    config = req("config.plugins.org"),
  },
  {
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup()
    end,
    cmd = "ToggleTerm",
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
}
