-- Custom group with an opaque bg the toast window is forced to use,
-- bypassing the Normal → NotifyXBody chain (which falls through to the
-- transparent Normal when tokyonight `transparent = true` is on).
vim.api.nvim_set_hl(0, "NotifyOpaqueBg", { bg = "#1a1a1a" })
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("notify_opaque_bg", { clear = true }),
  callback = function() vim.api.nvim_set_hl(0, "NotifyOpaqueBg", { bg = "#1a1a1a" }) end,
})

require("notify").setup({
  -- silence the "NotifyBackground has no background" warning; this is
  -- only used by fade-stage opacity-blend math.
  background_colour = "#000000",
  on_open = function(win)
    if vim.api.nvim_win_is_valid(win) then
      vim.wo[win].winhighlight = "Normal:NotifyOpaqueBg,NormalNC:NotifyOpaqueBg,FloatBorder:NotifyOpaqueBg"
      vim.wo[win].winblend = 0
    end
  end,
})
vim.notify = require("notify")

-- sQ: pull up dismissed notifications. Uses the Telescope notify extension
-- when available, else dumps the history into a scratch buffer.
vim.keymap.set("n", "sQ", function()
  local ok, telescope = pcall(require, "telescope")
  if ok and telescope.extensions and telescope.extensions.notify then
    telescope.extensions.notify.notify()
  else
    require("notify")._print_history()
  end
end, { silent = true, desc = "Notify history" })
pcall(function() require("telescope").load_extension("notify") end)
