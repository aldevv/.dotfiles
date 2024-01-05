return {
  "folke/trouble.nvim",
  config = function()
    vim.keymap.set("n", "]d",
      function()
        -- jump to the next item, skipping the groups
        require("trouble").next({ skip_groups = true, jump = true })
      end
      , { noremap = true, silent = true, desc = "Next diagnostic Trouble" })

    vim.keymap.set("n", "[d",
      function()
        -- jump to the previous item, skipping the groups
        require("trouble").previous({ skip_groups = true, jump = true })
      end
      , { noremap = true, silent = true, desc = "Previous diagnostic Trouble" })
  end,
  opts = {
    icons = false,                  -- use devicons for filenames
    mode = "workspace_diagnostics", -- "workspace_diagnostics", "document_diagnostics", "quickfix", "lsp_references", "loclist"
  },
}
