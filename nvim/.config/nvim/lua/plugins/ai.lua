return {
  -- {
  --   "github/copilot.vim",
  --   enabled = true,
  --   init = function()
  --     vim.cmd([[
  --       let g:copilot_no_tab_map = v:true
  --       imap <silent><script><expr> <c-j> copilot#Accept("\<c-j>")
  --     ]])
  --     vim.g.copilot_filetypes = {
  --       ["*"] = true,
  --       ["txt"] = false,
  --       ["md"] = false,
  --       [""] = false,
  --       -- ["docker-compose"] = true,
  --       -- dockerfile = true,
  --       -- json = true,
  --       -- yaml = true,
  --       -- sh = true,
  --       -- lua = true,
  --       -- go = true,
  --       -- rust = true,
  --       -- js = true,
  --       -- ts = true,
  --       -- jsx = true,
  --       -- tsx = true,
  --       -- python = true,
  --     }
  --   end,
  -- },
  {
    -- using this because it sets the workspace automatically
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    copilot_model = "",
    opts = {
      suggestion = {
        auto_trigger = true,
        hide_during_completion = true,
        keymap = {
          accept = "<C-j>",
          -- defaults
          next = "<C-S-]>",
          prev = "<C-S-[>",
          dismiss = "<M-S-]>",
        },
      },
      filetypes = {
        [""] = false,
        text = false,
        markdown = true,
      },
    },
  },
  {
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    opts = {
      default = {
        prompt_for_file_name = false,
        file_name = "%Y-%m-%d-%H-%M-%S",
      },
    },
    keys = {
      {
        "<leader>mp",
        function()
          require("img-clip").paste_image()
        end,
        desc = "Paste Image",
      },
    }
  },
  {
    "ravitemer/mcphub.nvim",
    enabled = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    build = "npm install -g mcp-hub@4.2.1", -- Installs `mcp-hub` node binary globally
    config = function()
      require("mcphub").setup()
    end
  }
}
