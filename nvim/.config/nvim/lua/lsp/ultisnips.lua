vim.g.UltiSnipsExpandTrigger = "<a-t>"
vim.g.UltiSnipsJumpForwardTrigger = "<a-t>"
vim.g.UltiSnipsJumpBackwardTrigger = "<a-s>"
vim.g.UltiSnipsListSnippets = "<c-tab>"
vim.g.UltiSnipsSnippetDirectories = { "my_snippets" ,"UltiSnips"}

-- nnoremap <a-t> i<c-r>=UltiSnips#JumpForwards()<cr>
-- snoremap <a-t> <Esc>:call UltiSnips#JumpForwards()<cr>
-- doesn't work for autocmd because of ultisnip
-- autocmd BufNewFile * :silent call feedkeys("\<space>I")
local M = {}
M.mappings = require("cmp_nvim_ultisnips.mappings")
return M
