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
      },
    },
  },
  {
    -- https://codecompanion.olimorris.dev/getting-started.html
    "olimorris/codecompanion.nvim",
    dependencies = {
      "ravitemer/mcphub.nvim",
      { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
      { "nvim-lua/plenary.nvim" },
      { "saghen/blink.cmp" },
      -- optional
      -- https://codecompanion.olimorris.dev/installation.html#img-clip-nvim
      -- use :PasteImage
      -- Add mcphub.nvim as a dependency
      {
        "HakonHarnes/img-clip.nvim",
        opts = {
          filetypes = {
            codecompanion = {
              prompt_for_file_name = false,
              template = "[Image]($FILE_PATH)",
              use_absolute_path = true,
            },
          },
        },
      },
    },
    opts = {
      strategies = {
        -- https://codecompanion.olimorris.dev/configuration/adapters.html
        -- https://docs.github.com/en/copilot/using-github-copilot/ai-models/changing-the-ai-model-for-copilot-chat
        -- choose: https://docs.github.com/en/copilot/using-github-copilot/ai-models/choosing-the-right-ai-model-for-your-task

        -- cost: https://docs.github.com/en/copilot/managing-copilot/monitoring-usage-and-entitlements/about-premium-requests
        -- you can set the model with model = "claude-sonnet-4-20250514" or similar
        chat = {
          adapter = {
            name = "copilot",
            -- if no model is specified, it will use the default model
            -- model = "claude-3.7-sonnet"
            model = "claude-sonnet-4"
          },
          keymaps = {
            close = {
              modes = {
                n = "<C-c>",
                i = "<C-c>",
              },
              index = 3,
              callback = function()
                require("codecompanion").toggle()
              end,
              description = "Toggle Chat",
            },
          },
        },

        inline = { adapter = "copilot" },
      },
      extensions = {
        mcphub = {
          callback = "mcphub.extensions.codecompanion",
          opts = {
            make_vars = true,
            make_slash_commands = true,
            show_result_in_chat = true
          }
        }
      }
    },
  },
  {
    "ravitemer/mcphub.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    build = "npm install -g mcp-hub@latest", -- Installs `mcp-hub` node binary globally
    config = function()
      require("mcphub").setup()
    end
  }
}
