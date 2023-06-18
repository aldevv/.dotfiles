-- put hover signature_help and cmp help transparent

-- local colorscheme = "kanagawa"
-- local colorscheme = "nvimgelion"
local colorscheme = "eva01"
if require("utils.lua.lazy").is_plugin_loaded(colorscheme) then
  vim.cmd("colorscheme " .. colorscheme)
end

-- transparency
vim.cmd("hi Normal guibg=NONE ctermbg=NONE")

require("config.appearance.legacy")
require("config.appearance.colors")
require("config.appearance.lsp")
require("config.appearance.folding")
