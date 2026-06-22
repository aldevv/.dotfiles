vim.opt.termguicolors = true
local function req(module)
  return function(name, opts)
    require(module)
  end
end
vim.g.mapleader = require("utils.lua.misc").replace_termcodes("<Space>")
-- vim.g.maplocalleader = "\\" -- this is backspace bro don't ask me why

return {
  -- tpope grab-bag: text-objects + dot-repeat compose with everyday edits, so
  -- VeryLazy is fine; the rest defer to their commands.
  { "tpope/vim-surround", event = "VeryLazy" },
  { "tpope/vim-repeat",   event = "VeryLazy" },
  { "tpope/vim-dotenv",   cmd = { "Dotenv" } },
  { "tpope/vim-dispatch", cmd = { "Dispatch", "Make", "Focus", "Start" } },
  -- Workspace-specific projectionist heuristics (e.g. ~/work/.nvim.lua) set
  -- g:projectionist_heuristics via exrc; do not put project-specific config here.
  { "tpope/vim-projectionist", cmd = { "A", "AS", "AV", "AT", "Etype" }, event = "VeryLazy" },

  { "mbbill/undotree", cmd = "UndotreeToggle" },
  { "bkad/CamelCaseMotion", event = "VeryLazy" },
  "nvim-tree/nvim-web-devicons",
  {
    -- TODO: wait for merge
    -- https://github.com/ThePrimeagen/harpoon/pull/614
    "ThePrimeagen/harpoon",

    -- https://github.com/ThePrimeagen/harpoon/commit/2cd4e03372f7ee5692c8caa220f479ea07970f17
    -- waiting for https://github.com/ThePrimeagen/harpoon/pull/557 to be merged
    -- custom key function makes harpoon useless atm (22/07/2024)
    -- branch = "harpoon2",
    commit = "2cd4e03372f7ee5692c8caa220f479ea07970f17",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VeryLazy",
    config = req("config.plugins.harpoon"),
  },
  {
    "kevinhwang91/nvim-ufo",
    event = "BufReadPost",
    config = req("config.plugins.ufo"),
    dependencies = { "kevinhwang91/promise-async", "nvim-treesitter/nvim-treesitter" },
  },
  {
    "stevearc/overseer.nvim",
    cmd = { "OverseerOpen", "OverseerClose", "OverseerToggle", "OverseerRun", "OverseerInfo", "OverseerBuild" },
    config = req("config.plugins.overseer"),
  },
  {
    "coffebar/neovim-project",
    cmd = { "Neovim", "NeovimProjectLoadRecent", "NeovimProjectDiscover", "NeovimProjectHistory" },
    keys = {
      { "<leader>tp", "<cmd>NeovimProjectHistory<cr>", desc = "neovim-project history" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "Shatur/neovim-session-manager",
    },
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
    "armyers/Vim-Jinja2-Syntax",
    ft = { "jinja.html", "jinja" },
  },

  -- sets comments according to filetype, not treesitter, helps for custom buffers with a set
  -- filetype
  {
    "numToStr/Comment.nvim",
    keys = {
      { "gc", mode = { "n", "v" } },
      { "gb", mode = { "n", "v" } },
      "gcc", "gbc",
    },
    config = req("config.plugins.comment"),
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" }, -- better commentstring using treesitter
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
    cmd = { "Refactor" },
    keys = {
      { "<leader>rr", mode = { "n", "v" } },
    },
    config = req("config.plugins.refactoring"),
  },
  {
    "akinsho/toggleterm.nvim",
    cmd = { "ToggleTerm", "ToggleTermToggleAll", "TermExec" },
    keys = { [[<c-\>]] },
    config = function()
      require("toggleterm").setup({})
    end,
  },
  {
    "ianding1/leetcode.vim",
    cmd = { "LeetLogin", "LeetTabs", "LeetList", "LeetTest", "LeetSubmit", "LeetReset" },
    build = "pip3 install keyring browser-cookie3 --user",
    config = function()
      -- Values: 'cpp', 'java', 'python', 'python3', 'csharp', 'javascript', 'ruby', 'swift', 'golang', 'scala', 'kotlin', 'rust'.
      -- Default value is 'cpp'.
      vim.g.leetcode_solution_filetype = "golang"
      vim.g.leetcode_browser = "firefox"
    end,
  },
}
