-- post-colorscheme highlight overrides. The colorscheme itself is applied
-- by lua/plugins/colors.lua (tokyonight). This file only adds transparency
-- and a few tweaks on top.

-- this is so is not overwritten by my colorscheme
-- vim.cmd([[
-- function! CmpColors()
-- highlight! CmpItemAbbrDeprecated guibg=NONE gui=strikethrough guifg=#808080
-- " blue
-- highlight! CmpItemAbbrMatch guibg=NONE guifg=#569CD6
-- highlight! link CmpItemAbbrMatchFuzzy CmpItemAbbrMatch
-- " light blue
-- highlight! CmpItemKindVariable guibg=NONE guifg=#9CDCFE
-- highlight! link CmpItemKindInterface CmpItemKindVariable
-- highlight! link CmpItemKindText CmpItemKindVariable
-- " pink
-- highlight! CmpItemKindFunction guibg=NONE guifg=#C586C0
-- highlight! link CmpItemKindMethod CmpItemKindFunction
-- " front
-- highlight! CmpItemKindKeyword guibg=NONE guifg=#D4D4D4
-- highlight! link CmpItemKindProperty CmpItemKindKeyword
-- highlight! link CmpItemKindUnit CmpItemKindKeyword
-- endfunction
--   augroup user_colors
--     autocmd!
--     autocmd ColorScheme * call CmpColors()
--   augroup END
-- ]])

-- transparency
vim.api.nvim_set_hl(0, "Normal", { bg = "NONE", ctermbg = "NONE" })
vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#262626", ctermbg = 235 })

-- LineNr / CursorLineNr: darkyellow + bold. Re-applied on ColorScheme so
-- tokyonight (or any swap) doesn't drop the bold attribute or fg back to
-- its theme default.
local function set_linenr_hl()
  vim.api.nvim_set_hl(0, "LineNr",       { bold = true, fg = "#e0b040", bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "CursorLineNr", { bold = true, fg = "#ffd787", bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "LineNrAbove",  { bold = true, fg = "#e0b040", bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "LineNrBelow",  { bold = true, fg = "#e0b040", bg = "NONE", ctermbg = "NONE" })
end
set_linenr_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("linenr_keep_bold", { clear = true }),
  callback = set_linenr_hl,
})

vim.api.nvim_set_hl(0, "CopilotSuggestion", { fg = "#9ef87a" })

-- -- transparent float for harpoon
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
vim.api.nvim_set_hl(0, "FloatBorder", { bg = "NONE" })
vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "NONE" })
vim.api.nvim_set_hl(0, "TelescopeBorder", { bg = "NONE" })

-- nvim-notify body backgrounds: keep them opaque + level-colored so toasts
-- read as red/yellow/blue against the transparent terminal. Without these,
-- they'd inherit NormalFloat=NONE and disappear.
vim.api.nvim_set_hl(0, "NotifyERRORBody", { bg = "#3f1d1d" })
vim.api.nvim_set_hl(0, "NotifyWARNBody",  { bg = "#3f3a1d" })
vim.api.nvim_set_hl(0, "NotifyINFOBody",  { bg = "#1d2a3f" })
vim.api.nvim_set_hl(0, "NotifyDEBUGBody", { bg = "#1f1f1f" })
vim.api.nvim_set_hl(0, "NotifyTRACEBody", { bg = "#2a1f3f" })

require("ui.folding")
