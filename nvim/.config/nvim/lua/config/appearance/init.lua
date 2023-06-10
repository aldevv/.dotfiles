-- put hover signature_help and cmp help transparent

local colorscheme = "kanagawa"
if _is_plugin_loaded(colorscheme) then
	vim.cmd("colorscheme " .. colorscheme)
end

-- transparency
vim.cmd("hi Normal guibg=NONE ctermbg=NONE")

require("config.appearance.legacy")
require("config.appearance.folding")
-- leave this last
require("config.appearance.colors")
require("config.appearance.lsp")
