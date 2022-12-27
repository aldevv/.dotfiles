-- TODO: put all of these in the after folder!
vim.opt.termguicolors = true -- this variable must be enabled for colors to be applied properly
require("config.appearance.legacy")
require("config.appearance.folding")
-- leave this last
require("config.appearance.colors")
require("config.appearance.lsp")
