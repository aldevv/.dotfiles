return {
  {
    "echasnovski/mini.diff",
    version = false,
    config = function()
      require("mini.diff").setup({
        view = {
          style = "sign",
          -- signs = { add = "+", change = "~", delete = "-" },
          -- signs = { add = "┃", change = "┃", delete = "_" },
          signs = { add = "", change = "", delete = "" },
        },
        mappings = {
          apply = "<leader>gh",
          reset = "<leader>gH",
          textobject = "<leader>gh",
        },
        -- options = {
        --   linematch = 20,
        -- },
      })
      vim.keymap.set("n", "<leader>gsb", function()
        require("mini.diff").toggle_overlay()
      end, { silent = true })

      -- to quickfix list
      vim.keymap.set("n", "<leader>gsq", function()
        vim.fn.setqflist(require("mini.diff").export("qf"))
      end, { silent = true })
    end,
  },
  {
    -- lines with mini.diff are too ugly
    "lewis6991/gitsigns.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { hl = "GitSignsAdd", text = "│", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
          change = {
            hl = "GitSignsChange",
            text = "│",
            numhl = "GitSignsChangeNr",
            linehl = "GitSignsChangeLn",
          },
          delete = {
            hl = "GitSignsDelete",
            text = "_",
            numhl = "GitSignsDeleteNr",
            linehl = "GitSignsDeleteLn",
          },
          topdelete = {
            hl = "GitSignsDelete",
            text = "‾",
            numhl = "GitSignsDeleteNr",
            linehl = "GitSignsDeleteLn",
          },
          changedelete = {
            hl = "GitSignsChange",
            text = "~",
            numhl = "GitSignsChangeNr",
            linehl = "GitSignsChangeLn",
          },
        },
        numhl = false,
        linehl = false,
      })
    end,
  },
}
