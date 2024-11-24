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
    -- TODO: wait for merge
    -- https://github.com/ThePrimeagen/harpoon/pull/614
    "ThePrimeagen/harpoon",

    -- https://github.com/ThePrimeagen/harpoon/commit/2cd4e03372f7ee5692c8caa220f479ea07970f17
    -- waiting for https://github.com/ThePrimeagen/harpoon/pull/557 to be merged
    -- custom key function makes harpoon useless atm (22/07/2024)
    -- branch = "harpoon2",
    commit = "2cd4e03372f7ee5692c8caa220f479ea07970f17",
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
    "github/copilot.vim",
    enabled = true,
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
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    enabled = false,
    branch = "canary",
    dependencies = {
      { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
      { "nvim-lua/plenary.nvim" },  -- for curl, log wrapper
    },
    opts = {
      debug = false, -- Enable debugging
      -- See Configuration section for rest
    },
    cmd = { "CopilotChat", "CopilotChatExplain", "CopilotChatTests", "CopilotChatDocs" },
    -- See Commands section for default commands if you want to lazy load on them
  },

  -- sets comments according to filetype, not treesitter, helps for custom buffers with a set
  -- filetype
  {
    "numToStr/Comment.nvim",
    config = req("config.plugins.comment"),
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" }, -- better commentstring using treesitter
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
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup({
        -- float_opts = {
        -- 	width = function()
        -- 		return math.floor(vim.o.columns * 0.7)
        -- 	end,
        -- 	height = function()
        -- 		return math.floor(vim.o.lines * 0.7)
        -- 	end,
        -- },
      })
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
}
