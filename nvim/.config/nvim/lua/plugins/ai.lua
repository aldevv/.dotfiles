return {
  {
    "github/copilot.vim",
    enabled = true,
    init = function()
      vim.cmd([[
        let g:copilot_no_tab_map = v:true
        imap <silent><script><expr> <c-j> copilot#Accept("\<c-j>")
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
    -- https://codecompanion.olimorris.dev/getting-started.html
    "olimorris/codecompanion.nvim",
    dependencies = {
      { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
      { "nvim-lua/plenary.nvim" },
      { "saghen/blink.cmp" },
      -- optional
      -- https://codecompanion.olimorris.dev/installation.html#img-clip-nvim
      -- use :PasteImage
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
        chat = { adapter = "copilot", },

        inline = { adapter = "copilot" },
      },
      opts = {
        log_level = "INFO",
      },
    },
  },
}
