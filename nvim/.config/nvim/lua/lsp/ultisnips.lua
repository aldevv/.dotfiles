vim.g.UltiSnipsExpandTrigger = "<a-s>"
vim.g.UltiSnipsJumpForwardTrigger = "<a-k>"
vim.g.UltiSnipsJumpBackwardTrigger = "<a-K>"
-- vim.g.UltiSnipsListSnippets = "<c-tab>"
vim.g.UltiSnipsSnippetDirectories = { "my_snippets", "UltiSnips" }

-- nnoremap <a-t> i<c-r>=UltiSnips#JumpForwards()<cr>
-- snoremap <a-t> <Esc>:call UltiSnips#JumpForwards()<cr>
-- doesn't work for autocmd because of ultisnip
-- autocmd BufNewFile * :silent call feedkeys("\<space>I")
local M = {}
M.mappings = require("cmp_nvim_ultisnips.mappings")
return M
