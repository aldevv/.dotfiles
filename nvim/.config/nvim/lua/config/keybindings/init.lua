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

local map = vim.keymap.set
local h = "~/.config/nvim"

local desc = function(desc)
    return vim.tbl_extend("keep", nor_s, { desc = desc })
end

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
map("", "N", "mzJ`z", nor) -- lines
map("n", "E", "i<cr><esc>k$", nor) -- lines
map("v", "E", ":s/\\n/ /g<cr>$x", nor) -- lines

-- map("n", "!!", ":.!", nor)
-- map("n", "!.", ".!bash", nor)

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

-- s commands
map("n", "sq", "<cmd>lua require('notify').dismiss()<cr>", nor_s)
map("n", "ss", "<cmd>silent Ex<cr>", nor_s)
map("n", "st", "<cmd>silent Texplore<cr>", nor_s)
map("n", "sv", "<cmd>silent Vexplore<cr>", nor_s)
map("n", "sn", "<cmd>call CreateFileEnter()<cr>", nor_s)
map("n", "sN", "<cmd>call CreateFileTouch()<cr>", nor_s)
map("n", "sD", "<cmd>call CreateDir()<cr>", nor_s)
map("n", "sd", "<cmd>bd<cr>", nor_s)
map("n", "si", "<Plug>(InsertSkeleton)", s)
-- 'cd' towards the directory in which the current file is edited
-- but only change the path for the current window
map("n", "sc", "<cmd>lcd %:h<cr>", desc("'cd' towards the directory in which the current file is edited"))

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
map("", "<leader>C", ":lua require('utils.lua.copilot').toggle_copilot()<cr>", nor)
map("", "<leader>,cc", ":lua require('utils.lua.copilot').toggle_copilot()<cr>", nor)
map("", "<leader>,cC", ":Copilot<cr>", nor)
map("", "<leader>,cs", ":Copilot status<cr>", nor)
map("", "<leader>,cS", ":Copilot setup<cr>", nor)

-- terminal
map("n", "<leader>sñ", ":botright terminal<cr>", nor)
map("n", "<a-q>", "<cmd>ToggleTerm direction=float<cr>", nor)
map("t", "<a-q>", "<cmd>ToggleTerm direction=float<cr>", nor)

-- terminal
map("t", "<a-'>", "<c-\\><c-n>", nor_s)

-- folders
map("n", "<F1>", ":e " .. h .. "/lua/config/keybindings/init.lua<cr>", nor_s)

-- shortcuts
require("shortcuts")
-- opening config file (using shortcuts script now)
-- map("n", "<localleader>.l", ":e .vscode/launch.json<cr>", nor_s)

-- -- moving to folder (using shortcuts script now)
-- map("n", "<localleader>v.", "<cmd>cd " .. h .. "<cr> | <cmd>e .<cr>", nor_s)

-- defaults override
map("", "gh", ":h <c-r><c-w>|resize 15<cr>", nor) -- select mode, not used
map("", "<leader>sh", "<c-l>", {})

local uv = require("utils.vanilla.core")
-- qf
uv.quickfix_toggle_definition()
map("n", "<c-q>q", ":call ToggleQuickFix(0)<cr>", nor_s)
map("n", "<c-q>Q", ":call ToggleQuickFix(1)<cr>", nor_s)
map("n", "<c-q>k", ":cnext<cr>zzzv", nor)
map("n", "<c-q>K", ":cprev<cr>zzzv", nor)

-- ql
uv.location_toggle_definition()
vim.keymap.del("n", "<c-l>")
map("n", "<c-l>l", ":call ToggleLocation(0)<cr>", nor_s)
map("n", "<c-l>L", ":call ToggleLocation(1)<cr>", nor_s)
map("n", "<c-l>k", ":lnext<cr>zzzv", nor)
map("n", "<c-l>K", ":lprev<cr>zzzv", nor)

-- folding
map("", "ze", "zk", nor)
map("", "zn", "zk", nor)
map("", "zD", "zE", nor)

-- tagbar
map("n", "<c-h>", ":TagbarToggle<cr>", nor_s)
map("n", "<c-s-h>", ":LSoutlineToggle<cr>", nor_s)

-- hop
-- map("n", "s", ":HopChar1<cr>", nor_s)
-- map("o", "S", ":HopChar1<cr>", nor_s)

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
-- nnoremap <leader>gll :let g:_search_term = expand("%")<CR><bar>:Gclog -- %<CR>:call search(g:_search_term)<CR>
-- nnoremap <leader>gln :cnext<CR>:call search(_search_term)<CR>
-- nnoremap <leader>glp :cprev<CR>:call search(_search_term)<CR>-

-- prefix . --> commands
map("n", "<leader>.vo", ":noautocmd w | luafile %<cr>", nor_s)
map("n", "<leader>.vd", ":lua require('osv').launch({port=3333})<cr>", nor_s)
map("n", "<leader>.vD", ":lua require('osv').run_this()<cr>", nor_s)
map("n", "<leader>.sb", "ggO#!/bin/bash<escape>", nor_s)
map("n", "<leader>.sB", "ggO#!/bin/bash<escape>", nor_s)
map("n", "<leader>.sf", ":luafile %<cr>", nor)

require("config.keybindings.text-objs")

-- git worktrees
map("n", "gwc", ":Telescope git_worktree create_git_worktree<cr>", nor)
map("n", "gww", ":Telescope git_worktree git_worktrees<cr>", nor)
-- <Enter> - switches to that worktree
-- <c-d> - deletes that worktree
-- <c-f> - toggles forcing of the next deletion

-- fun
map("n", "<leader>,fv", ":VimBeGood<cr>", nor)
map("n", "<leader>,fa", ":VimApm<cr>", nor)
map("n", "<leader>,fA", ":VimApmShutdown<cr>", nor)

map("i", "€", "<plug>(emmet-expand-abbr)", {})
map("n", "<leader>u", ":UndotreeToggle<cr>", nor_s)
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
map("n", "sb", ":BrightestToggle<cr>", nor)

-- gv
map("n", "<leader>gv", ":GVcr>", nor)

-- rainbow
map("n", "sr", ":RainbowToggle<cr>", nor_s)

require("config.keybindings.fugitive")

-- obsession
map("n", "<leader>,ol", ":source %:h/Session.vim<bar> :Obsession<cr>", nor_s)
map("n", "<leader>,os", ":Obsession<CR>", nor_s)

-- vim-test

map("n", "<localleader>tn", ":lua require('neotest').run.run()<cr>", nor_s) -- run nearest
map("n", "<localleader>tx", ":lua require('neotest').run.stop()<cr>", nor_s) -- run nearest
map("n", "<localleader>tf", ":lua require('neotest').run.run(vim.fn.expand('%'))<cr>", nor_s)
map("n", "<localleader>ts", ":lua require('neotest').summary.toggle()<cr>", nor_s)
map("n", "<localleader>to", ":lua require('neotest').output.open({enter = true})<cr>", nor_s)
map("n", "<localleader>tl", ":lua require('neotest').run.run_last()<cr>", nor_s)
map("n", "<localleader>tk", ":lua require('neotest').jump.next({status = 'failed'})<cr>", nor_s)
map("n", "<localleader>tK", ":lua require('neotest').jump.prev({status = 'failed'})<cr>", nor_s)
map("n", "<localleader>tt", ":lua require('neotest').run.run({suite = true})<cr>", nor_s)
map("n", "<localleader>tS", ":lua require('neotest').run.run({suite = true})<cr>", nor_s)
map("n", "<localleader>tg", ":TestVisit<cr>", nor_s)
vim.cmd([[cnoreabbrev Tn TestNearest]])
vim.cmd([[cnoreabbrev Ts TestSuite]])
vim.cmd([[cnoreabbrev Tf TestFile]])
vim.cmd([[cnoreabbrev Tl TestLast]])

-- map("n", "<leader>Tn", ":TestNearest<cr>", nor_s)
-- map("n", "<leader>Tf", ":TestFile<cr>", nor_s)
-- map("n", "<leader>Tt", ":TestSuite<cr>", nor_s)
-- map("n", "<leader>Tl", ":TestLast<cr>", nor_s)
-- map("n", "<leader>Tg", ":TestVisit<cr>", nor_s)

-- macro range
map("x", "@", ":<C-u>call ExecuteMacroOverVisualRange()<cr>", nor_s)

-- sniprun
--keymaps not working
-- sniprun
-- map('v', '<leader>csr', '<Plug>SnipRun', s)
-- map('n', '<leader>cso', '<Plug>SnipRunOperator', s)
-- map('n', '<leader>csr', '<Plug>SnipRun', s)
vim.cmd([[
nmap <leader>,Sr <Plug>SnipRun
nmap <leader>,So <Plug>SnipRunOperator
vmap <leader>,Sr <Plug>SnipRun
]])

-- , configuration
map("n", "<leader>,li", ":LspInfo<cr>", nor_s)
map("n", "<leader>,lI", ":LspInstallInfo<cr>", nor_s)
map("n", "<leader>,ln", ":NullLsInfo<cr>", nor_s)

map("n", "<leader>,ps", ":PackerSync<cr>", nor)
map("n", "<leader>,pS", ":PackerStatus<cr>", nor)
map("n", "<leader>,pi", ":PackerInstall<cr>", nor)
map("n", "<leader>,pC", ":PackerClean<cr>", nor)
map("n", "<leader>,pu", ":PackerUpdate<cr>", nor)
map("n", "<leader>,pc", ":PackerCompile<cr>", nor)

require("config.keybindings.refactoring")
-- require("config.keybindings.lspsaga").load_mappings()
require("config.keybindings.overseer").load_mappings()

map("n", "<leader><leader>g", "<cmd>MindOpenMain<cr>", nor)
map("n", "<leader><leader>p", "<cmd>MindOpenProject global<cr>", nor)
map("n", "<leader><leader>P", "<cmd>MindOpenProject<cr>", nor)

map("n", "<leader>sl", "<cmd>IndentBlanklineToggle<cr>", nor)
-- map("n", "<leader>g", "<cmd>MindOpenProject")

-- curl
map("n", "<leader>.cb", "vip:w !bash<cr>", nor)
map("n", "<a-c>", "vip:w !bash<cr>", nor)

-- markdown
map("n", "<leader>.mp", "<cmd>MarkdownPreviewToggle<cr>", nor)

-- rest.nvim
map("n", "<localleader>rr", "<Plug>RestNvim<cr>", nor)
map("n", "<localleader>rp", "<Plug>RestNvimPreview<cr>", nor)
map("n", "<localleader>rl", "<Plug>RestNvimLast<cr>", nor)

-- dadbod
-- opening it in a new tab
map("n", "<localleader>Dd", ":tabedit | DBUI<cr>", {})
map("n", "<localleader>DD", ":DBUIToggle<cr>", {})
map("n", "<localleader>Da", ":DBUIAddConnection<cr>", {})
map("n", "<localleader>Df", ":DBUIFindBuffer<cr>", {})
map("n", "<localleader>Dq", ":DBUILastQueryInfo<cr>", {})
-- For queries, filetype is automatically set to sql. Also, two mappings is added for the sql filetype:
--
-- W - Permanently save query for later use (<Plug>(DBUI_SaveQuery))
-- E - Edit bind parameters (<Plug>(DBUI_EditBindParameters))

map("n", "<leader>,,", "<cmd>tabedit<cr>", nor)

function toggle_transparency()
    local normal = vim.api.nvim_command_output("hi Normal")
    -- if nil, then is transparent
    if string.find(normal, "guibg") == nil then
        local cur_theme = vim.api.nvim_command_output("colorscheme")
        vim.cmd("colorscheme " .. cur_theme)
        return
    end

    vim.cmd([[hi Normal guibg=NONE ctermbg=NONE]])
end

map("n", "sT", toggle_transparency, nor)

-- float

-- map("n", "<leader>ss", ":e .projections.json<cr>", {})

map(
    "n",
    "<leader>sp",
    "<cmd>lua require('utils.lua.misc').toggle_float_file('package.json')<cr>",
    desc("Open package.json file in a floating window")
)

map(
    "n",
    "<leader>sP",
    "<cmd>lua require('utils.lua.misc').toggle_float_file('.projections.json')<cr>",
    desc("Open .projections.json file in a floating window")
)

map(
    "n",
    "<leader>sr",
    "<cmd>lua require('utils.lua.misc').toggle_float_file('requirements.txt')<cr>",
    desc("Open requirements.txt file in a floating window")
)

map(
    "n",
    "<leader>sr",
    "<cmd>lua require('utils.lua.misc').toggle_float_file('Cargo.toml')<cr>",
    desc("Open Cargo.toml file in a floating window")
)
