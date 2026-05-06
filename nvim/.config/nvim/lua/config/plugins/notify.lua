local notify = require("notify")

notify.setup {
    background_colour = "#000000",
    fps = 30,
    icons = {
        DEBUG = "",
        ERROR = "",
        INFO = "",
        TRACE = "✎",
        WARN = "",
    },
    level = 2,
    minimum_width = 50,
    render = "default",
    stages = "fade_in_slide_out",
    timeout = 5000,
}

-- Replace vim.notify with a wrapper that still toasts via nvim-notify but
-- mirrors ERROR/WARN entries to :messages, since nvim-notify's toasts fade
-- and don't appear in the :messages history.
vim.notify = function(msg, level, opts)
  notify(msg, level, opts)
  if level == vim.log.levels.ERROR or level == vim.log.levels.WARN then
    vim.schedule(function()
      local hl = level == vim.log.levels.ERROR and "ErrorMsg" or "WarningMsg"
      local text = type(msg) == "table" and table.concat(msg, "\n") or tostring(msg)
      vim.api.nvim_echo({ { text, hl } }, true, {})
    end)
  end
end
