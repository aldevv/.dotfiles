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
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      vim.api.nvim_set_hl(0, "GitSignsAdd", { link = "GitSignsAdd" })
      vim.api.nvim_set_hl(0, "GitSignsChange", { link = "GitSignsChange" })
      vim.api.nvim_set_hl(0, "GitSignsDelete", { link = "GitSignsDelete" })

      require("gitsigns").setup({
        update_debounce = 500,
        -- skip bigfile buffers (vim.b.bigfile is set in config/automation/init.lua)
        attach_to_untracked = false,
        worktrees = nil,
        -- the heavy redraw on every keystroke is the dominant typing-cost
        -- in long files; debounce above is the main lever.
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
        on_attach = function(bufnr)
          local gs = require("gitsigns")
          local map = function(lhs, rhs)
            vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true })
          end
          map("]c", function()
            if vim.wo.diff then
              vim.cmd.normal({ "]c", bang = true })
            else
              gs.nav_hunk("next")
            end
          end)
          map("[c", function()
            if vim.wo.diff then
              vim.cmd.normal({ "[c", bang = true })
            else
              gs.nav_hunk("prev")
            end
          end)
          map("]p", gs.preview_hunk)
          map("[p", gs.preview_hunk)
        end,
      })
    end,
  },
}
