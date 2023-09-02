require("config.keybindings.legacy")
-- weired menmonics

-- <leader>o --> open diagnostics
-- <leader>, --> config
-- <leader>. --> commands

local s = { silent = true }
local nor = { noremap = true }
local e = { expr = true }
local b = { buffer = true }
local s_e = vim.tbl_extend("keep", s, e)
local nb = vim.tbl_extend("keep", nor, b)

local nor_s = vim.tbl_extend("keep", nor, s)
local nor_e = vim.tbl_extend("keep", nor, e)
local nor_e_s = vim.tbl_extend("keep", nor, e, s)

local map = vim.keymap.set
local h = "~/.config/nvim"

local desc = function(desc)
  return vim.tbl_extend("keep", nor_s, { desc = desc })
end

local descv = function(desc)
  return vim.tbl_extend("keep", nor, { desc = desc })
end

local descb = function(desc)
  return vim.tbl_extend("keep", nor, { desc = desc, buffer = true })
end

-- backlog
-- <a-?>
-- <a-t>
-- <a-h>
-- ¿
-- <leader>N
-- essential
-- this is to disalbe <Del> default behaviour
map("n", "<Del>", "<cmd>WhichKey <Del> <cr>", nor)

-- colemak
map("n", "n", "j", nor)
map("n", "e", "k", nor)
map("n", "j", "e", nor)

map("n", "gk", "gn", nor)

-- ===================
-- map("n", "l", "i", nor)
-- map("x", "l", "i", nor)
-- vim.cmd([[
-- nnoremap l i
-- nnoremap i l
-- vnoremap i l
-- ]])
-- map("o", "l", "i", nor)

-- map("n", "i", "l", nor)
-- map("x", "i", "l", nor)
-- map("o", "i", "l", nor)

-- ===================

map({ "n" }, "l", "i", nor) --the o messes with mini.ai and targets.vim https://github.com/echasnovski/mini.nvim/issues/206
map({ "n", "x" }, "i", "lzv", nor)

-- useful for targets.vim
map("x", "l", "i", nor)
map("o", "l", "i", nor)

-- map("o", "lp", "ip", nor) -- mini.ai doesn't set this, also doesn't work with gulw
-- map("n", "i", "lzv", nor) -- zv so it also works with folds
map("", "N", "mzJ`z", nor)

map("n", "w", "zvw", nor) -- zv so it also works with folds

map("o", "e", "k", nor)
map("o", "n", "j", nor)

map("x", "e", "k", nor)
map("x", "n", "j", nor)
map("x", "j", "e", nor)

map("v", "N", ":m '>+1<CR>gv=gv")
map("v", "E", ":m '<-2<CR>gv=gv")


-- add e and n movements to the jumplist!
map("n", "e", '(v:count > 1  ? "m\'" . v:count : "") . \'k\'', nor_e)
map("n", "n", '(v:count > 1  ? "m\'" . v:count : "") . \'j\'', nor_e)

-- generate checkpoints for undo
map("i", ",", ",<c-g>u", nor)
map("i", ".", ".<c-g>u", nor)
map("i", "!", "!<c-g>u", nor)
map("i", "?", "?<c-g>u", nor)

map("", "<c-d>", "<c-d>zz", nor)
map("", "<c-u>", "<c-u>zz", nor)

-- files
map("n", "sfn", "<cmd>call CreateFileEnter()<cr>", nor_s)
map("n", "sft", "<cmd>call CreateFileTouch()<cr>", nor_s)
map("n", "sfd", "<cmd>call CreateDir()<cr>", nor_s)

-- s commands
map("n", "sq", "<cmd>lua require('notify').dismiss()<cr>", nor_s)

-- netrw commands
map("n", "ss", "<cmd>silent Ex<cr>", { remap = true })
map("n", "sS", "<cmd>silent Ex .<cr>", s)
map("n", "st", "<cmd>silent Texplore<cr>", s)
map("n", "sT", "<cmd>silent Texplore .<cr>", s)
map("n", "sv", "<cmd>silent Vexplore<cr>", s)
map("n", "sV", "<cmd>silent Vexplore .<cr>", s)

map("n", "sd", "<cmd>bd<cr>", nor_s)
map("n", "sI", "<cmd>IndentBlanklineToggle<cr>", desc("disable indentlines"))

map("n", "som", "set modifiable!", nor)
map("n", "sow", "set wrap!", nor)
map("n", "sos", "set wrapscan!", nor)
map("n", "syfp", ":let @+=expand('%:p')<cr>", descv("yank filepath"))
map("n", "syfP", ":let @+=expand('%')<cr>", descv("yank relative filepath"))
map("n", "syp", ":let @+=execute('pwd')->split('\\n')[0]<cr>", descv("yank pwd")) -- doing the split because it removes the newline prefix

-- 'cd' towards the directory in which the current file is edited
-- but only change the path for the current window
map("n", "sc", "<cmd>lcd %:h<cr>", desc("'cd' towards the directory in which the current file is edited"))

-- for pasting (no replacing of the register when pasting in visual mode)
map("x", "p", "pgvy", nor_s)

-- file path
map("n", "<leader>sg", ":lua print(vim.fn.expand('%:p'))<cr>", nor)


-- map("v", "<a-n>", ":m '>+1<cr>gv=gv", nor)
-- map("v", "<a-e>", ":m '<-2<cr>gv=gv", nor)
-- map("i", "<a-e>", "<esc>:m .-2<cr>==a", nor)
-- map("i", "<a-n>", "<esc>:m .+1<cr>==a", nor)
-- map("n", "<a-e>", ":m .-2<cr>==", nor)
-- map("n", "<a-n>", ":m .+1<cr>==", nor)

-- this way also works but no fallback
-- vim.keymap.set("i", "<a-y>", "copilot#Accept('<a-y>')",
--   { replace_keycodes = false, silent = true, expr = true, script = true })
map("i", "<a-cr>", "<cr>")
map("i", "<a-y>", function()
  local copilot_keys = vim.fn["copilot#Accept"]()
  if copilot_keys ~= "	" then
    vim.api.nvim_feedkeys(copilot_keys, "i", true)
    return
  end
end, nor_s)

map("i", "<m-\\>", "<Plug>(copilot-suggest)", nor) -- no need to enable copilot with this
map("i", "<a-}>", "<Plug>(copilot-next)", nor)
map("i", "<a-{>", "<Plug>(copilot-previous)", nor)
map("i", "<c-}>", "<Plug>(copilot-dismiss)", nor)
map("n", "Ec", ":lua require('utils.lua.copilot').toggle_copilot()<cr>", desc("Copilot Toggle "))
map("n", "Ep", ":Copilot panel<cr>", desc("Copilot Panel [[ and ]] to jump solutions")) --use [[ and ]] to jump solutions
map("n", "<leader>,cc", ":lua require('utils.lua.copilot').toggle_copilot()<cr>", nor)
map("n", "<leader>,cC", ":Copilot<cr>", nor)
map("n", "<leader>,cs", ":Copilot status<cr>", nor)
map("n", "<leader>,cS", ":Copilot setup<cr>", nor)
map("n", "<leader>,cp", ":Copilot panel<cr>", nor) --use [[ and ]] to jump solutions

map("n", "<leader>,sn", function()
  vim.cmd(":e ~/.config/nvim/my_snippets/luasnips/" .. vim.bo.ft .. ".lua")
end, descv("edit snippet"))

-- terminal
map("n", "sñ", ":botright terminal<cr>", nor)
map({ "n", "t" }, "<a-q>", "<cmd>ToggleTerm direction=float<cr>", nor)

map({ "n", "t" }, "<a-1>", "<cmd>ToggleTerm direction=horizontal<cr>", nor)
map({ "n", "t" }, "<a-2>", "<cmd>ToggleTerm direction=vertical size=40<cr>", nor)
map({ "n", "t" }, "<a-3>", "<cmd>ToggleTerm direction=tab<cr>", nor)

-- terminal
map("t", "<a-'>", "<c-\\><c-n>", nor_s)
map("t", "<c-g>", "<c-\\><c-n>gT", nor_s)
map("t", "<c-s-g>", "<c-\\><c-n>gt", nor_s)

-- folders
map("n", "<F1>", ":e " .. h .. "/lua/config/keybindings/init.lua<cr>", nor_s)
map("n", "<leader><C-f>", "<cmd>silent !tmux neww nf<CR>", nor_s)

-- delete without saving in register

map({ "n", "v" }, "Q", [["_d]])

-- shortcuts
-- require("shortcuts")
local ok, err = pcall(require, "shortcuts")
if not ok then
  require("notify")("failed to load shortcuts: \n" .. err, "error")
end

-- opening config file (using shortcuts script now)
map("n", "<leader>,la", function()
  vim.fn.system("[ ! -d .vscode ] && mkdir .vscode")
  vim.cmd(":e .vscode/launch.json")
end, nor_s)

-- -- moving to folder (using shortcuts script now)
-- map("n", "<localleader>v.", "<cmd>cd " .. h .. "<cr> | <cmd>e .<cr>", nor_s)

-- defaults override
map("", "gh", ":h <c-r><c-w>|resize 16<cr>", nor) -- select mode, not used
map("", "<leader>sh", "<c-l>", {})

local uv = require("utils.vanilla.core")
-- qf
uv.quickfix_toggle_definition()
map("n", "<c-q>q", ":call ToggleQuickFix(0)<cr>", nor_s)
map("n", "<c-q>Q", ":call ToggleQuickFix(1)<cr>", nor_s)
map("n", "<c-q>k", ":cnext<cr>zzzv", nor)
map("n", "<c-q>K", ":cprev<cr>zzzv", nor)
map("n", "<c-n>", ":cnext<cr>zzzv", nor)
map("n", "<c-e>", ":cprev<cr>zzzv", nor)

-- ql
uv.location_toggle_definition()
vim.keymap.del("n", "<c-l>")

map("n", "<c-l>l", ":call ToggleLocation(0)<cr>", nor_s)
map("n", "<c-l>L", ":call ToggleLocation(1)<cr>", nor_s)
map("n", "<c-l>k", ":lnext<cr>zzzv", nor)
map("n", "<c-l>K", ":lprev<cr>zzzv", nor)

-- tagbar
map("n", "<c-h>", ":TagbarToggle<cr>", nor_s)
map("n", "<c-s-h>", ":LSoutlineToggle<cr>", nor_s)
-- hop
-- map("n", "s", ":HopChar1<cr>", nor_s)
-- map("o", "S", ":HopChar1<cr>", nor_s)

-- leader commands
-- -----------------

-- telescope
require("config.keybindings.telescope").load_mappings()

-- nvim-tree
map("n", "<leader>se", ":NvimTreeToggle<cr>", nor_s)

-- treesitter
map("n", "<leader>,tt", ":TSPlaygroundToggle<cr>", nor_s)
map("n", "<leader>,th", ":TSHighlightCapturesUnderCursor<cr>", nor_s)

-- harpoon
require("config.keybindings.harpoon").load_mappings()

-- nnoremap <leader>gll :let g:_search_term = expand("%")<CR><bar>:Gclog -- %<CR>:call search(g:_search_term)<CR>
-- nnoremap <leader>gln :cnext<CR>:call search(_search_term)<CR>
-- nnoremap <leader>glp :cprev<CR>:call search(_search_term)<CR>-

-- prefix . --> commands
map("n", "<leader>.vz", ":so<cr>", nor_s)
map("n", "<leader>.vd", ":lua require('osv').launch({port=3333})<cr>", nor_s)
map("n", "<leader>.vD", ":lua require('osv').run_this()<cr>", nor_s)
map("n", "<leader>.sb", "ggO#!/bin/bash<escape>", nor_s)
map("n", "<leader>.sB", "ggO#!/bin/bash<escape>", nor_s)
map("n", "<leader>.vf", ":luafile %<cr>", nor)
map("v", "<leader>!", ":w !", nor)
map("n", "Ñ", ":w !", nor)
map("v", "Ñ", ":w !", nor)
map("n", "!q", ":!", nor)
map("v", "!q", ":!", nor)

require("config.keybindings.text-objs")


-- <Enter> - switches to that worktree
-- <c-d> - deletes that worktree
-- <c-f> - toggles forcing of the next deletion

-- fun
map("n", "<leader>,fv", ":VimBeGood<cr>", nor)
map("n", "<leader>,fa", ":VimApm<cr>", nor)
map("n", "<leader>,fA", ":VimApmShutdown<cr>", nor)

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
map("n", "sm", ":MaximizerToggle<CR>", nor_s)
map("v", "sm", ":MaximizerToggle<CR>gv", nor_s)

-- brightest
map("n", "sb", ":BrightestToggle<cr>", nor)

require("config.keybindings.fugitive")

map("n", "<leader>,sf", ":source %<cr>", nor)
map("n", "<leader>,ss", ":source ~/.config/nvim/lua/lsp/luasnip.lua<cr>", nor)

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
map("n", "<leader>,La", ":Lazy<cr>", nor)
map("n", "<leader>,Ll", ":Lazy log<cr>", nor)
map("n", "<leader>,Lp", ":Lazy profile<cr>", nor)
map("n", "<leader>,Lr", ":Lazy restore<cr>", nor)

map("n", "<leader>,lr", ":LspRestart<cr>", nor)
map("n", "<leader>,li", ":LspInfo<cr>", nor)
map("n", "<leader>,ls", ":LspStart ", nor)
map("n", "<leader>,lS", ":LspStop ", nor)
map("n", "<leader>,ll", ":LspLog<cr>", nor)

map("n", "<leader>,ni", ":NullLsInfo<cr>", nor)
map("n", "<leader>,nl", ":NullLsLog<cr>", nor)

map("n", "<leader>,Ma", ":Mason<cr>", nor)
map("n", "<leader>,Ml", ":MasonLog<cr>", nor)
map("n", "<leader>,Mu", ":MasonUpdate<cr>", nor)

map("c", "<c-b>", ' <C-R><C-V> <C-\\>eexpand("%")<cr>', nor)
map("c", "<c-s-b>", ' <C-R><C-V> <C-\\>eexpand("%:p:h")<cr>/', nor)

-- map("n", "<leader>,ps", ":PackerSync<cr>", nor)
-- map("n", "<leader>,pS", ":PackerStatus<cr>", nor)
-- map("n", "<leader>,pi", ":PackerInstall<cr>", nor)
-- map("n", "<leader>,pC", ":PackerClean<cr>", nor)
-- map("n", "<leader>,pu", ":PackerUpdate<cr>", nor)
-- map("n", "<leader>,pc", ":PackerCompile<cr>", nor)

require("config.keybindings.refactoring")
-- require("config.keybindings.lspsaga").load_mappings()
require("config.keybindings.overseer").load_mappings()

-- map("n", "<leader><leader>g", "<cmd>MindOpenMain<cr>", nor)
-- map("n", "<leader><leader>p", "<cmd>MindOpenProject global<cr>", nor)
-- map("n", "<leader><leader>P", "<cmd>MindOpenProject<cr>", nor)

map("n", "<leader>sl", "<cmd>IndentBlanklineToggle<cr>", nor)
-- map("n", "<leader>g", "<cmd>MindOpenProject")

-- curl
map("n", "<leader>.cb", "vip:w !bash<cr>", nor)
map("n", "<a-c>", "vip:w !bash<cr>", nor)

-- markdown
map("n", "<leader>,mp", "<cmd>MarkdownPreviewToggle<cr>", nor)


-- rest.nvim
map("n", "Srr", "<Plug>RestNvim<cr>", nor)
map("n", "Srp", "<Plug>RestNvimPreview<cr>", nor)
map("n", "Srl", "<Plug>RestNvimLast<cr>", nor)

-- dadbod
-- opening it in a new tab
map("n", "Sbd", ":tabedit | DBUI<cr>", {})
map("n", "SbD", ":DBUIToggle<cr>", {})
map("n", "Sba", ":DBUIAddConnection<cr>", {})
map("n", "Sbf", ":DBUIFindBuffer<cr>", {})
map("n", "Sbq", ":DBUILastQueryInfo<cr>", {})
-- For queries, filetype is automatically set to sql. Also, two mappings is added for the sql filetype:
--
-- W - Permanently save query for later use (<Plug>(DBUI_SaveQuery))
-- E - Edit bind parameters (<Plug>(DBUI_EditBindParameters))

map("n", "<leader>,,", "<cmd>tabedit<cr>", nor)

local function toggle_transparency()
  local normal = vim.api.nvim_command_output("hi Normal")
  -- if nil, then is transparent
  if string.find(normal, "guibg") == nil then
    local cur_theme = vim.api.nvim_command_output("colorscheme")
    vim.cmd("colorscheme " .. cur_theme)
    return
  end

  vim.cmd([[hi Normal guibg=NONE ctermbg=NONE]])
end

-- map("n", "sT", toggle_transparency, nor)
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
  "<leader>sc",
  "<cmd>lua require('utils.lua.misc').toggle_float_file('Cargo.toml')<cr>",
  desc("Open Cargo.toml file in a floating window")
)

-- commands

map(
  "n",
  "<leader><leader>tw",
  ':topleft 40vs $ATOMIC/todo/work/<c-r>=system("stamp")<cr><cr>',
  desc("create work todo")
)
map(
  "n",
  "<leader><leader>tp",
  ':topleft 40vs $ATOMIC/todo/projects/<c-r>=system("stamp")<cr><cr>',
  desc("create work todo")
)
map(
  "n",
  "<leader><leader>tl",
  ':topleft 40vs $ATOMIC/todo/learn/<c-r>=system("stamp")<cr><cr>',
  desc("create work todo")
)

map("n", "<leader>.dgpa", "<cmd>Start . _dgpa<cr>", descv("push all my stuff"))
map("n", "<leader>.dgpn", "<cmd>Start . _dgp $NOTES<cr>", descv("push notes"))
map("n", "<leader>.dgpd", "<cmd>Start . _dgp $DOTFILES<cr>", descv("push dotfiles"))
map("n", "<leader>.dgpw", "<cmd>Start . _dgp $WIKI<cr>", descv("push wiki"))

map("n", "<leader>.ant", "<cmd>Spawn st -e bash -c ant<cr>", desc("create inbox note in new terminal"))
map("n", "<leader>.anT", ":Spawn st -e bash -c 'ant '<left>", descv("create custom note in new terminal"))
map("n", "<leader>.br", ":e README.md<cr>", descv("open README.md"))

map(
  "n",
  "<leader>.st",
  "<cmd>Spawn st -e bash -c 'cd $(dirname %); zsh'<cr>",
  desc("terminal instance in current folder")
)

map(
  "n",
  "<leader>.r",
  "<cmd>Spawn st -e bash -c 'ranger $(dirname %); zsh'<cr>",
  desc("create ranger instance in current folder")
)

-- language specific
-- for horizontal splits using dispatch
vim.g.dispatch_tmux_height = "35% -v"
map("n", "<leader><leader>d", ":Dispatch ", descv("Dispatch _"))
map("n", "<leader><leader>D", ":Dispatch! ", descv("Dispatch! _"))
map("n", "<leader><leader>s", ":Start ", descv("Start _"))
map("n", "<leader><leader>S", ":Start! ", descv("Start! _"))

-- run entr
map("n", "<leader><leader>r", function()
  local cmd = vim.fn.input("Enter the command entr will run: ")
  vim.cmd("silent !tmux split-window -h -p 45; tmux send-keys -t 2 'en " .. cmd .. "' Enter; tmux select-pane -L")
end, nor_s)
map("n", "<leader><leader>R", function()
  local cmd = vim.fn.input("Enter the command entr will run: ")
  vim.cmd("silent !tmux split-window -v -p 35; tmux send-keys -t 2 'en " .. cmd .. "' Enter; tmux select-pane -L")
end, nor_s)

-- go
map("n", "<leader><leader>g", function()
  vim.cmd("silent !tmux split-window -h -p 45; tmux send-keys -t 2 'en go run .' Enter; tmux select-pane -L")
end, nor_s)
map("n", "<leader><leader>G", function()
  vim.cmd("silent !tmux split-window -v -p 35; tmux send-keys -t 2 'en go run .' Enter; tmux select-pane -L")
end, nor_s)

map("n", "<leader><leader>p", function()
  vim.cmd("silent !tmux split-window -h -p 45; tmux send-keys -t 2 'en python %' Enter; tmux select-pane -L")
end, nor_s)
map("n", "<leader><leader>P", function()
  vim.cmd("silent !tmux split-window -v -p 35; tmux send-keys -t 2 'en python %' Enter; tmux select-pane -L")
end, nor_s)

-- resize

map("n", "<S-Down>", "5<c-w>-", nor_s)
map("n", "<S-Up>", "5<c-w>+", nor_s)
map("n", "<S-Right>", "5<c-w>>", nor_s)
map("n", "<S-Left>", "5<c-w><", nor_s)

-- tabs
-- map("n", "<Right>", function()
--     pcall(vim.cmd, [[checktime]])
--     vim.api.nvim_feedkeys("gt", "n", true)
-- end, nor_s)
--
-- map("n", "<Left>", function()
--     pcall(vim.cmd, [[checktime]])
--     vim.api.nvim_feedkeys("gT", "n", true)
-- end, nor_s)

map({ "n", "v" }, "<CR>", "za")
map({ "n", "v" }, "<s-CR>", "zA")
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    map({ "n", "v" }, "<CR>", "<CR>", { buffer = true })
  end
})

-- for command line window
vim.api.nvim_create_autocmd("CmdwinEnter", {
  callback = function()
    map({ "n", "v" }, "<CR>", "<CR>", { noremap = true, buffer = true })
    map({ "n", "v" }, "<C-c>", "<C-c>", { noremap = true, buffer = true })
  end
})

map("n", "<c-l><c-l>", ":nohl<cr>")

-- color picker
map("n", "<leader>C", "<cmd>PickColor<cr>", nor)

-- leetcode
-- used because adding package something in go gives an error when submitting
local no_first_line_cmd = function(cmd)
  local bufnr = vim.api.nvim_get_current_buf()
  local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)
  vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, { "" })
  vim.cmd(cmd)
  vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, first_line)
  local cw = require("utils.lua.misc").replace_termcodes("<c-w>")
  local cr = require("utils.lua.misc").replace_termcodes("<cr>")
  vim.api.nvim_feedkeys(cw .. "e:w" .. cr .. cw .. "n", "m", true)
end

vim.keymap.set("n", "<leader>,fll", ":LeetCodeList<cr>")
vim.keymap.set("n", "<leader>,flt", function()
  no_first_line_cmd("LeetCodeTest")
end, desc("LeetCodeTest"))
vim.keymap.set("n", "<leader>,fls", function()
  no_first_line_cmd("LeetCodeSubmit")
end, desc("LeetCodeSubmit"))
-- vim.keymap.set("n", "<leader>,flt", ":LeetCodeTest<cr>")
-- vim.keymap.set("n", "<leader>,fls", ":LeetCodeSubmit<cr>")
vim.keymap.set("n", "<leader>,fli", ":LeetCodeSignIn<cr>")

-- paste image
map("n", "<leader>,mP", ":PasteImg<cr>")
map("n", "m<leader>", ":PasteImg<cr>")
-- map("v", "m<leader>", function()
--   local selection = require "utils.lua.misc".get_visual_selection()
--   if selection == nil then
--     vim.print("no selection")
--     return
--   end
--   return "c[" .. selection .. "](" .. selection .. ")"
-- end, { expr = true })
