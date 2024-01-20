-- put hover signature_help and cmp help transparent

-- this is so is not overwritten by my colorscheme
vim.cmd([[
  augroup user_colors
    autocmd!
    " autocmd ColorScheme * highlight CmpItemAbbr guifg=LightBlue
    " autocmd ColorScheme * highlight CmpItemMatch guifg=Pink
    " autocmd ColorScheme * highlight CmpItemKind guifg=Orange
  augroup END
]])
-- local colorscheme = "kanagawa"
local colorscheme = "tokyonight"
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

require("ui.folding")
