require("overseer").setup({
  templates = { "builtin", "user.run_script" },
})

vim.keymap.set("n", "ñr", ":OverseerRun<cr>")
vim.keymap.set("n", "ñR",
  function()
    local cmd = vim.fn.input("Enter command: ")
    vim.cmd("OverseerRunCmd " .. cmd)
  end
)
vim.keymap.set("n", "ñp", ":OverseerToggle!<cr>")
vim.keymap.set("n", "ñv", function()
    local cur_buf = vim.api.nvim_get_current_buf()
    local all_bufs = vim.api.nvim_list_bufs()
    for _, v in ipairs(all_bufs) do
      if vim.fn.getbufvar(v, "&filetype") == "OverseerOutput" then
        vim.cmd("wincmd l")
        vim.cmd('set filetype=""')
        vim.cmd("q")
        return
      end
    end
    vim.cmd("OverseerQuickAction open vsplit")
    local new_buf = vim.api.nvim_get_current_buf()
    if new_buf == cur_buf then
      return
    end
    vim.cmd("set filetype=OverseerOutput")
    vim.cmd("wincmd h")
  end,
  { desc = "open most recent task output", silent = true })
vim.keymap.set("n", "ña", ":OverseerAction<cr>")
-- saved in .local/state/nvim/overseer/
vim.keymap.set("n", "ñz", ":OverseerSaveBundle<cr>")
vim.keymap.set("n", "ñl", ":OverseerLoadBundle<cr>")
