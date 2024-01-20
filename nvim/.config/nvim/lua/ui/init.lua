-- put hover signature_help and cmp help transparent

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
local colorscheme = "kanagawa"
-- local colorscheme = "tokyonight"
-- local colorscheme = "eva01"
vim.cmd("colorscheme " .. colorscheme)

-- transparency
vim.api.nvim_set_hl(0, "Normal", { bg = "NONE", ctermbg = "NONE" })
vim.api.nvim_set_hl(0, "LineNr", { bold = true, fg = "darkyellow", ctermbg = "NONE" })
vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#262626", ctermbg = 235 })

vim.api.nvim_set_hl(0, "CopilotSuggestion", { fg = "#9ef87a" })

-- -- transparent float for harpoon
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
vim.api.nvim_set_hl(0, "FloatBorder", { bg = "NONE" })
vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "NONE" })
vim.api.nvim_set_hl(0, "TelescopeBorder", { bg = "NONE" })

require("ui.folding")
