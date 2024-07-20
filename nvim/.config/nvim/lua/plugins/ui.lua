local function req(module)
  return function(name, opts)
    require(module)
  end
end
return {
  {
    "nvim-lualine/lualine.nvim",
    config = req("config.plugins.lualine"),
  },
  {
    "rcarriga/nvim-notify",
    config = function()
      require("config.plugins.notify")
      vim.notify = require("notify")
    end,
  },
  {
    "stevearc/dressing.nvim",
    opts = {},
  },
  {
    "j-hui/fidget.nvim",
    tag = "legacy",
    event = "LspAttach",
    opts = {
      sources = {
        ["null-ls"] = { ignore = true },
        copilot = { ignore = true },
      },
    },
  },
  {
    "folke/todo-comments.nvim",
    opts = {
      keywords = {
        FIX = {
          icon = " ", -- icon used for the sign, and in search results
          color = "error", -- can be a hex color, or a named color (see below)
          alt = { "FIXME", "BUG", "FIXIT", "ISSUE" }, -- a set of other keywords that all map to this FIX keywords
          -- signs = false, -- configure signs for some keywords individually
        },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = " ", color = "error", alt = { "ERROR", "REMOVE", "DELETE" } },
        WARNING = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
        DEPRECATED = { icon = " ", color = "warning", alt = { "DEPRECATED", "XXX" } },
        PERFORMANCE = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
        NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
        TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
      },
      gui_style = {
        fg = "NONE", -- The gui style to use for the fg highlight group.
        bg = "BOLD", -- The gui style to use for the bg highlight group.
      },
    },
    dependencies = "nvim-lua/plenary.nvim",
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function()
      local M = require("utils.lua.highlight")
      local hooks = require("ibl.hooks")
      hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        vim.api.nvim_set_hl(0, "IndentBlanklineIndent1", { fg = M.colors.dark_red })
        vim.api.nvim_set_hl(0, "IndentBlanklineIndent2", { fg = M.colors.dark_yellow })
        vim.api.nvim_set_hl(0, "IndentBlanklineIndent3", { fg = M.colors.dimm_green })
        vim.api.nvim_set_hl(0, "IndentBlanklineIndent4", { fg = M.colors.dimm_purple })
        vim.api.nvim_set_hl(0, "IndentBlanklineIndent5", { fg = M.colors.white })
        vim.api.nvim_set_hl(0, "IndentBlanklineIndent6", { fg = M.colors.bracket_grey })
        vim.api.nvim_set_hl(0, "IndentBlanklineContextChar", { fg = M.colors.visual_grey })
        vim.api.nvim_set_hl(0, "IndentBlanklineContextStart", { sp = M.colors.dimm_black })
        vim.api.nvim_set_hl(0, "IndentBlanklineContextSpaceChar", {})
        vim.api.nvim_set_hl(0, "Whitespace", { fg = M.colors.cursor_grey })
      end)
      require("ibl").setup({
        indent = {
          highlight = {
            "IndentBlanklineIndent1",
            "IndentBlanklineIndent2",
            "IndentBlanklineIndent3",
            "IndentBlanklineIndent4",
            "IndentBlanklineIndent5",
            "IndentBlanklineIndent6",
          },
          char = "┆",
        },
        whitespace = {
          remove_blankline_trail = true,
        },
      })
    end,
    ft = { "lua", "javascript", "javascriptreact", "typescript" },
  },
}
