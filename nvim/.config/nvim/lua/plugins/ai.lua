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
    },
    opts = {
      strategies = {
        chat = { adapter = "copilot" },
        inline = { adapter = "copilot" },
      },
      opts = {
        log_level = "DEBUG",
      },
    },
  },
}
