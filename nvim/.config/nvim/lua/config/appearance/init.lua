-- put hover signature_help and cmp help transparent

-- local colorscheme = "kanagawa"
-- local colorscheme = "tokyonight"
local colorscheme = "eva01"
if require("utils.lua.lazy").is_plugin_loaded(colorscheme) then
	vim.cmd("colorscheme " .. colorscheme)
end

-- transparency
vim.cmd([[
  hi Normal guibg=NONE ctermbg=NONE
  hi LineNr gui=bold guifg=darkyellow ctermbg=NONE
  hi ColorColumn guibg=#262626 ctermbg=235
]])

vim.api.nvim_set_hl(0, "CopilotSuggestion", { fg = "#9ef87a" })

-- transparent float
vim.cmd([[
    execute 'hi! NormalFloat guibg=0'
]])
vim.cmd([[
    augroup cmp
        execute 'hi! CmpItemAbbr guifg=LightGreen'
        execute 'hi! CmpItemKind guifg=Orange'
        " execute 'hi! CmpItemAbbrMatch guifg=Pink'
    augroup END
]])

require("config.appearance.folding")
