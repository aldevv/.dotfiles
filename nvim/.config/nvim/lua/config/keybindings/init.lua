-- weird menmonics

-- <leader>o --> open diagnostics
-- <leader>, --> config
-- <leader>. --> commands

local s = { silent = true }
local nor = { noremap = true }
local e = { expr = true }
local s_e = vim.tbl_extend("keep", s, e)

local nor_s = vim.tbl_extend("keep", nor, s)
local nor_e = vim.tbl_extend("keep", nor, e)
local nor_e_s = vim.tbl_extend("keep", nor, e, s)

local map = vim.api.nvim_set_keymap
local h = "~/.config/nvim"
-- backlog
-- <a-?>
-- <a-i>
-- <a-t>
-- <a-h>
-- ¿
-- <leader>N
-- essential

-- colemak
-- map("", "n", "j", nor)
-- map("", "e", "k", nor)
-- map("", "j", "e", nor)
-- map("", "gj", "ge", nor)
-- map("", "gJ", "gE", nor)
-- map("", "l", "i", nor)
-- map("", "i", "l", nor)
-- map("v", "i", "l", nor)
-- map("", "k", "nzzzv", nor)
-- map("", "K", "Nzzzv", nor)
-- map("", "ge", "gk", nor)
-- map("", "gn", "gj", nor)
-- map("", "gk", "gn", nor)
-- map("", "gE", "gJ", nor) -- lines
map("", "E", "mzJ`z", nor) -- lines

-- jumplist mutations
map("n", "e", '(v:count > 5  ? "m\'" . v:count : "") . \'k\'', nor_e)
map("n", "n", '(v:count > 5  ? "m\'" . v:count : "") . \'j\'', nor_e)

-- generate checkpoints for undo
map("i", ",", ",<c-g>u", nor)
map("i", ".", ".<c-g>u", nor)
map("i", "!", "!<c-g>u", nor)
map("i", "?", "?<c-g>u", nor)

map("", "<c-d>", "<c-d>zz", nor)
map("", "<c-u>", "<c-u>zz", nor)

-- netrw
map(
    "n",
    "<leader>sp",
    ":if &ft != 'netrw' && !exists('g:netrw_buffer') | :execute ':Lex ' . expand(\"%:p:h\") | let g:netrw_buffer=bufnr('%') | else | :Lex | unlet g:netrw_buffer | endif<cr>",
    nor_s
)
map("n", "<leader>sP", ":Lex<cr>", nor_s)
map("n", "<leader>ss", ":Ex<cr>", nor_s)

-- for pasting (no replacing of the register when pasting in visual mode)
map("x", "p", "pgvy", nor_s)

-- file path
map("n", "<leader>sg", ":lua print(vim.fn.expand('%:p'))<cr>", nor)

map("v", "<a-down>", ":m '>+1<cr>gv=gv", nor)
map("v", "<a-up>", ":m '<-2<cr>gv=gv", nor)
map("i", "<a-up>", "<esc>:m .-2<cr>==a", nor)
map("i", "<a-down>", "<esc>:m .+1<cr>==a", nor)
map("n", "<a-up>", ":m .-2<cr>==", nor)
map("n", "<a-down>", ":m .+1<cr>==", nor)

-- map("v", "<a-n>", ":m '>+1<cr>gv=gv", nor)
-- map("v", "<a-e>", ":m '<-2<cr>gv=gv", nor)
-- map("i", "<a-e>", "<esc>:m .-2<cr>==a", nor)
-- map("i", "<a-n>", "<esc>:m .+1<cr>==a", nor)
-- map("n", "<a-e>", ":m .-2<cr>==", nor)
-- map("n", "<a-n>", ":m .+1<cr>==", nor)

map("i", "<c-y>", "copilot#Accept('<CR>')", vim.tbl_extend("keep", s_e, { script = true }))
map("", "<leader>cc", ":lua require('utils.lua.keybindings').toggle_copilot()<cr>", nor)

-- terminal
map("n", "<leader>sñ", ":botright terminal<cr>", nor)

-- snippets
map("n", "<leader>si", "<Plug>(InsertSkeleton)", s)

-- terminal
map("t", "<a-'>", "<c-\\><c-n>", nor_s)

-- folders
map("n", "<F1>", ":e " .. h .. "/lua/config/keybindings/init.lua<cr>", nor_s)
map("n", "<F5>", "<c-^>", nor_s)

map("n", "<localleader>V.", ":e " .. h .. "/init.lua<cr>", nor_s)
map("n", "<localleader>Vs", ":e " .. h .. "/lua/config/settings.lua<cr>", nor_s)
map("n", "<localleader>Vp", ":e " .. h .. "/lua/plugins.lua<cr>", nor_s)
map("n", "<localleader>Va", ":e " .. h .. "/lua/config/automation/init.lua<cr>", nor_s)
map("n", "<localleader>Vk", ":e " .. h .. "/lua/config/keybindings/init.lua<cr>", nor_s)
map("n", "<localleader>Vl", ":e " .. h .. "/lua/lsp/init.lua<cr>", nor_s)
map("n", "<localleader>VP", ":e " .. h .. "/modules/plugins.vim<cr>", nor_s)

-- defaults override
map("", "gh", ":h <c-r><c-w>|resize 15<cr>", nor) -- select mode, not used
map("", "<leader>sh", "<c-l>", {})

local uv = require("utils.vanilla.core")
-- qf
uv.quickfix_toggle_definition()
map("n", "<c-q>q", ":call ToggleQuickFix(0)<cr>", nor_s)
map("n", "<c-q>Q", ":call ToggleQuickFix(1)<cr>", nor_s)
map("n", "<c-q>n", ":cnext<cr>zzzv", nor)
map("n", "<c-q>e", ":cprev<cr>zzzv", nor)

-- ql
uv.location_toggle_definition()
map("n", "<c-l>l", ":call ToggleLocation(0)<cr>", nor_s)
map("n", "<c-l>L", ":call ToggleLocation(1)<cr>", nor_s)
map("n", "<c-l>n", ":lnext<cr>zzzv", nor)
map("n", "<c-l>e", ":lprev<cr>zzzv", nor)

-- folding
map("", "ze", "zk", nor)
map("", "zn", "zk", nor)
map("", "zD", "zE", nor)

-- tagbar
map("n", "<c-h>", ":TagbarToggle<cr>", nor_s)

-- hop
map("n", "s", ":HopChar1<cr>", nor_s)
map("o", "S", ":HopChar1<cr>", nor_s)

-- leader commands
-- -----------------
-- whichkey workaround (no BS allowed)
map("n", "<BS>", ":WhichKey \\<cr>", nor_s)

-- telescope
require("config.keybindings.telescope").load_mappings()

-- nvim-tree
map("n", "<leader>se", ":NvimTreeToggle<cr>", nor_s)

-- treesitter
map("n", "<leader>stt", ":TSPlaygroundToggle<cr>", nor_s)
map("n", "<leader>sth", ":TSHighlightCapturesUnderCursor<cr>", nor_s)

-- harpoon
require("config.keybindings.harpoon").load_mappings()

-- dap
require("config.keybindings.dap").load_mappings()
--fugitive
-- nnoremap <leader>gll :let g:_search_term = expand("%")<CR><bar>:Gclog -- %<CR>:call search(g:_search_term)<CR>
-- nnoremap <leader>gln :cnext<CR>:call search(_search_term)<CR>
-- nnoremap <leader>glp :cprev<CR>:call search(_search_term)<CR>-

-- prefix . --> commands
map("n", "<leader>.vo", ":noautocmd w | luafile %<cr>", nor_s)
map("n", "<leader>.vd", ":lua require('osv').launch({port=3333})<cr>", nor_s)
map("n", "<leader>.vD", ":lua require('osv').run_this()<cr>", nor_s)

require("config.keybindings.text-objs")

-- git worktrees
map("n", "gwc", ":Telescope git_worktree create_git_worktree<cr>", nor)
map("n", "gww", ":Telescope git_worktree git_worktrees<cr>", nor)
-- <Enter> - switches to that worktree
-- <c-d> - deletes that worktree
-- <c-f> - toggles forcing of the next deletion

-- fun
map("n", "<leader>cfv", ":VimBeGood<cr>", nor)
map("n", "<leader>cfa", ":VimApm<cr>", nor)
map("n", "<leader>cfA", ":VimApmShutdown<cr>", nor)

map("i", "€", "<plug>(emmet-expand-abbr)", {})
map("n", "<leader>su", ":UndotreeToggle<cr>", nor_s)
map("n", "<leader>sv", ":IndentLinesToggle<cr>", nor_s)

-- map('n', "gp", "<Plug>(ReplaceWithRegisterOperator)", nor_s)
-- map('n', "gpp", "<Plug>(ReplaceWithRegisterLine)", nor_s)
-- map('x', "gp", "<Plug>(ReplaceWithRegisterVisual)", nor_s)
--  only works like this

-- camelcase motion
map("", "<leader>j", "<Plug>CamelCaseMotion_e", s)
map("", "<leader>gj", "<Plug>CamelCaseMotion_ge", s)
map("", "<leader>w", "<Plug>CamelCaseMotion_w", s)
map("", "<leader>b", "<Plug>CamelCaseMotion_b", s)

map("o", "<leader>lw", "<Plug>CamelCaseMotion_iw", s)
map("x", "<leader>lw", "<Plug>CamelCaseMotion_iw", s)
map("o", "<leader>lb", "<Plug>CamelCaseMotion_ib", s)
map("x", "<leader>lb", "<Plug>CamelCaseMotion_ib", s)
map("o", "<leader>lj", "<Plug>CamelCaseMotion_ie", s)
map("x", "<leader>lj", "<Plug>CamelCaseMotion_ie", s)

-- visual move block

vim.cmd([[
vmap <down> <Plug>MoveBlockDown
vmap <up> <Plug>MoveBlockUp
vmap <left> <Plug>MoveBlockLeft
vmap <right> <Plug>MoveBlockRight
]])

-- maximizer
map("n", "<leader>sm", ":MaximizerToggle<CR>", nor_s)
map("v", "<leader>sm", ":MaximizerToggle<CR>gv", nor_s)

-- brightest
map("n", "<leader>sb", ":buffers<cr>", nor)
map("n", "<leader>,b", ":BrightestToggle<cr>", nor)

-- gv
map("n", "<leader>gv", ":GVcr>", nor)

-- rainbow
map("n", "<leader>sr", ":RainbowToggle<cr>", nor_s)

require("config.keybindings.fugitive")

-- obsession
map("n", "<leader>col", ":source %:h/Session.vim<bar> :Obsession<cr>", nor_s)
map("n", "<leader>cos", ":Obsession<CR>", nor_s)

-- vim-test

map("n", "<leader>Tn", ":TestNearest<cr>", nor_s)
map("n", "<leader>Tf", ":TestFile<cr>", nor_s)
map("n", "<leader>Ts", ":TestSuite<cr>", nor_s)
map("n", "<leader>Tl", ":TestLast<cr>", nor_s)
map("n", "<leader>Tg", ":TestVisit<cr>", nor_s)

-- macro range
map("x", "@", ":<C-u>call ExecuteMacroOverVisualRange()<cr>", nor_s)

-- sniprun
--keymaps not working
-- sniprun
-- map('v', '<leader>csr', '<Plug>SnipRun', s)
-- map('n', '<leader>cso', '<Plug>SnipRunOperator', s)
-- map('n', '<leader>csr', '<Plug>SnipRun', s)
vim.cmd([[
nmap <leader>csr <Plug>SnipRun
nmap <leader>cso <Plug>SnipRunOperator
vmap <leader>csr <Plug>SnipRun
]])

-- , configuration
map("n", "<leader>,li", ":LspInfo<cr>", nor_s)
map("n", "<leader>,lI", ":LspInstallInfo<cr>", nor_s)

map("n", "<leader>,ps", ":PackerStatus<cr>", nor)
map("n", "<leader>,pi", ":PackerInstall<cr>", nor)
map("n", "<leader>,pC", ":PackerClean<cr>", nor)
map("n", "<leader>,pu", ":PackerUpdate<cr>", nor)
map("n", "<leader>,pc", ":PackerCompile<cr>", nor)

require("config.keybindings.refactoring")
