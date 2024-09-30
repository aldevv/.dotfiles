return {
  -- {
  --   "echasnovski/mini.diff",
  --   version = false,
  --   config = function()
  --     require("mini.diff").setup({
  --       view = {
  --         style = "sign",
  --         -- signs = { add = "+", change = "~", delete = "-" },
  --         -- signs = { add = "┃", change = "┃", delete = "_" },
  --         signs = { add = "", change = "", delete = "" },
  --       },
  --       mappings = {
  --         apply = "<leader>gh",
  --         reset = "<leader>gH",
  --         textobject = "<leader>gh",
  --       },
  --       -- options = {
  --       --   linematch = 20,
  --       -- },
  --     })
  --     vim.keymap.set("n", "<leader>gsb", function()
  --       require("mini.diff").toggle_overlay()
  --     end, { silent = true, desc = "Git diff block" })
  --
  --     -- to quickfix list
  --     vim.keymap.set("n", "<leader>gsq", function()
  --       vim.fn.setqflist(require("mini.diff").export("qf"))
  --     end, { silent = true })
  --   end,
  -- },
  {
    -- lines with mini.diff are too ugly
    "lewis6991/gitsigns.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      vim.api.nvim_set_hl(0, "GitSignsAdd", { link = "GitSignsAdd" })
      vim.api.nvim_set_hl(0, "GitSignsChange", { link = "GitSignsChange" })
      vim.api.nvim_set_hl(0, "GitSignsDelete", { link = "GitSignsDelete" })

      require("gitsigns").setup({
        signs = {
          add = { text = "┃" },
          change = { text = "┃" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
          untracked = { text = "┆" },
        },
        signs_staged = {
          add = { text = "┃" },
          change = { text = "┃" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
          untracked = { text = "┆" },
        },
      })
      vim.keymap.set("n", "<leader>gsp", ":Gitsigns preview_hunk<CR>", { silent = true })
    end,
  },
}
