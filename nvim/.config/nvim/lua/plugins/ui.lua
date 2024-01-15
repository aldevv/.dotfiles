local function req(module)
  return function(name, opts)
    require(module)
  end
end
return {
  {
    "rcarriga/nvim-notify",
    config = function()
      require("core.notify")
      vim.notify = require("notify")
    end,
  },
  {
    "j-hui/fidget.nvim",
    tag = "legacy",
    event = "LspAttach",
    opts = {
      sources = {
        ["null-ls"] = { ignore = true },
        copilot = { ignore = true }
      }
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    config = req("config.appearance.lualine"),
  },
}
