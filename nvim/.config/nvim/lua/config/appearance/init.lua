-- put hover signature_help and cmp help transparent
vim.cmd([[
    hi clear SpellBad
    hi link SpellBad GruvboxRed
]])

require("config.appearance.legacy")
require("config.appearance.folding")
-- leave this last
require("config.appearance.colors")
require("config.appearance.lsp")
