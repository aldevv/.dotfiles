return

{
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  config = function()
    local M = require("utils.lua.highlight")
    local hooks = require "ibl.hooks"
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
        char = "┆"
      },
      whitespace = {
        remove_blankline_trail = true,
      },
    })
  end,
  ft = { "lua", "javascript", "javascriptreact", "typescript" }

}
