-- put hover signature_help and cmp help transparent

-- local colorscheme = "kanagawa"
-- local colorscheme = "tokyonight"
local colorscheme = "eva01"
if require("utils.lua.lazy").is_plugin_loaded(colorscheme) then
  vim.cmd("colorscheme " .. colorscheme)
end

-- transparency
vim.cmd("hi Normal guibg=NONE ctermbg=NONE")
vim.cmd("hi LineNr gui=bold guifg=darkyellow ctermbg=NONE")

vim.api.nvim_set_hl(0, "CopilotSuggestion", { fg = "#9ef87a" })

require("config.appearance.legacy")
require("config.appearance.colors")
require("config.appearance.lsp")
require("config.appearance.folding")
