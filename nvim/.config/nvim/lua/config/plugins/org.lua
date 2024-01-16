require("orgmode").setup_ts_grammar()
require("orgmode").setup({
  org_indent_mode = "indent",
  org_edit_src_content_indentation = 0,
  mappings = {
    text_objects = {
      inner_heading = "<ignore>",
      inner_subtree = "<ignore>",
    },
    org = {
      -- done because original mapping was NOT SILENT
      org_global_cycle = "<ignore>",
      org_cycle = "<ignore>", -- this is tab by default
      -- org_agenda_switch_to = "<ignore>",
    },
  },
})

-- done because original mapping was NOT SILENT
vim.api.nvim_create_autocmd("FileType", {
  pattern = "org",
  callback = function()
    vim.keymap.del("n", "<cr>")
    -- vim.keymap.del("n", "<s-cr>")
    -- vim.keymap.del("n", "zM")
    vim.keymap.set(
      "n",
      "<cr>",
      'za',
      { silent = true }
    )
    -- vim.keymap.set(
    --   "n",
    --   "<s-cr>",
    --   '<Cmd>lua require("orgmode").action("org_mappings.global_cycle")<CR>)',
    --   { silent = true }
    -- )
    vim.keymap.set(
      "n",
      "zM",
      '<Cmd>lua require("orgmode").action("org_mappings.global_cycle")<CR>)',
      { silent = true }
    )
  end,
})
