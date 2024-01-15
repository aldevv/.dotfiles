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
  "tpope/vim-surround",
  "tpope/vim-repeat",
  "mbbill/undotree",
  "bkad/CamelCaseMotion",
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = req("core.harpoon"),
    module = "harpoon",
  },
  {
    "kevinhwang91/nvim-ufo",
    config = req("core.ufo"),
    dependencies = { "kevinhwang91/promise-async", "nvim-treesitter/nvim-treesitter" },
  },
  {
    "stevearc/overseer.nvim",
    config = req("core.overseer")
  },
  {
    "ahmedkhalf/project.nvim",
    config = req("lsp.project"),
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
    config = req("core.comment"),
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" } -- better commentstring using treesitter
  },
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
    config = req("config.appearance.whichkey"),
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
    "nvim-orgmode/orgmode",
    config = req("core.org"),
  },
  {
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup()
    end,
    cmd = "ToggleTerm",
  },
  {
    "rest-nvim/rest.nvim",
    dev = true,
    dependencies = "nvim-lua/plenary.nvim",
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
