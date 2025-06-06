require("keybindings.legacy")
-- weired menmonics

-- <leader>o --> open diagnostics
-- <leader>, --> config
-- <leader>. --> commands

local s = { silent = true }
local nor = { noremap = true }
local e = { expr = true }

local nor_s = vim.tbl_extend("keep", nor, s)
local nor_e = vim.tbl_extend("keep", nor, e)

local map = vim.keymap.set
local h = "~/.config/nvim"

local desc = function(text)
  return vim.tbl_extend("keep", nor_s, { desc = text })
end

local descv = function(text)
  return vim.tbl_extend("keep", nor, { desc = text })
end

-- backlog
-- <a-?>
-- <a-h>
-- essential

-- colemak
map("n", "n", "j", nor)
map("n", "e", "k", nor)
map({ "n", "o" }, "j", "e", nor)

if not os.getenv("USE_QWERTY") then
  map("n", "n", "j", nor)
  map("n", "e", "k", nor)
  map({ "n", "o" }, "j", "e", nor)

  map("n", "gk", "gn", nor)
  map("n", "cj", "ce", nor)


  map("n", "l", "i", nor) --the o messes with mini.ai and targets.vim https://github.com/echasnovski/mini.nvim/issues/206
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
end
-- =================== end colemak

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
map("n", "si", "<cmd>IndentBlanklineToggle<cr>", desc("Toggle indentlines"))

map("n", "som", "set modifiable!", nor)
map("n", "sow", "set wrap!", nor)
map("n", "sos", "set wrapscan!", nor)

map("n", "syf", function()
  local path = vim.fn.expand("%:p")
  local relative_path = vim.fn.fnamemodify(path, ":~:.")
  vim.fn.setreg("+", relative_path)
end, descv("yank relative filepath"))

map("n", "syF", ":let @+=expand('%:p:')<cr>", descv("yank filepath"))
map("n", "syp", ":let @+=execute('pwd')->split('\\n')[0]<cr>", descv("yank pwd")) -- doing the split because it removes the newline prefix

-- 'cd' towards the directory in which the current file is edited
-- but only change the path for the current window
map("n", "sc", "<cmd>lcd %:h<cr>", desc("'cd' towards the directory in which the current file is edited"))

-- for pasting (no replacing of the register when pasting in visual mode)
map("x", "p", "pgvy", nor_s)

-- file path
map("n", "sg", ":lua print(vim.fn.expand('%:p'))<cr>", nor)

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

map("n", "<leader>,sn", function()
  vim.cmd(":e ~/.config/nvim/my_snippets/luasnips/" .. vim.bo.ft .. ".lua")
end, descv("edit snippet"))

-- terminal
require("keybindings.term")

-- folders
map("n", "<F1>", ":e " .. h .. "/lua/config/keybindings/init.lua<cr>", nor_s)
map("n", "<leader><C-f>", "<cmd>silent !tmux neww nf<CR>", nor_s)

-- delete without saving in register
map({ "n", "v" }, "X", [["_d]])

-- shortcuts
-- require("shortcuts")
local ok, err = pcall(require, "shortcuts")
if not ok then
  require("notify")("failed to load shortcuts: \n" .. err, "error")
end

-- -- moving to folder (using shortcuts script now)
-- map("n", "<localleader>v.", "<cmd>cd " .. h .. "<cr> | <cmd>e .<cr>", nor_s)

-- defaults override
map("", "gh", ":h <c-r><c-w>|resize 16<cr>", nor) -- select mode, not used

local uv = require("utils.vanilla.core")
-- qf
uv.quickfix_toggle_definition()
map("n", "Q", ":call ToggleQuickFix(0)<cr>", nor_s)
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

-- leader commands
-- -----------------

-- telescope
require("keybindings.telescope").load_mappings()

-- harpoon
if pcall(require, "harpoon") then
  require("keybindings.harpoon").load_mappings()
end

-- nnoremap <leader>gll :let g:_search_term = expand("%")<CR><bar>:Gclog -- %<CR>:call search(g:_search_term)<CR>
-- nnoremap <leader>gln :cnext<CR>:call search(_search_term)<CR>
-- nnoremap <leader>glp :cprev<CR>:call search(_search_term)<CR>-

-- prefix . --> commands
map("n", "<leader>.vz", ":so<cr>", nor_s)
map("n", "<leader>.vd", ":lua require('osv').launch({port=3333})<cr>", nor_s)
map("n", "<leader>.vD", ":lua require('osv').run_this()<cr>", nor_s)
map("n", "<leader>.sb", "ggO#!/usr/bin/env bash<escape>", nor_s)

map("n", "<leader>.sB", "ggO#!/usr/bin/env bash<escape>", nor_s)
map("n", "<leader>.vf", ":luafile %<cr>", nor)
map("n", "!w", ":w !", nor)
map("v", "!w", ":w !", nor)

require("keybindings.text-objs")

-- <Enter> - switches to that worktree
-- <c-d> - deletes that worktree
-- <c-f> - toggles forcing of the next deletion

-- fun
map("n", "<leader>,fv", ":VimBeGood<cr>", nor)
map("n", "<leader>,fa", ":VimApm<cr>", nor)
map("n", "<leader>,fA", ":VimApmShutdown<cr>", nor)

map("n", "<leader>u", ":UndotreeToggle<cr>", nor_s)

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

require("keybindings.fugitive")

map("n", "<leader>,sf", ":source %<cr>", nor)
map("n", "<leader>,ss", ":source ~/.config/nvim/lua/lsp/luasnip.lua<cr>", nor)

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

require("keybindings.refactoring")

-- markdown
map("n", "<leader>,mp", "<cmd>MarkdownPreviewToggle<cr>", nor)

map("n", "<leader>,,", "<cmd>tabedit<cr>", nor)

local function toggle_transparency()
  local normal = vim.api.nvim_exec2("hi Normal", { output = true }).output
  if string.find(normal, "guibg") ~= nil then
    vim.cmd([[hi Normal guibg=NONE ctermbg=NONE]])
    return
  end
  local cur_theme = vim.api.nvim_exec2("colorscheme", { output = true }).output
  vim.cmd("colorscheme " .. cur_theme)
end
map("n", "sT", toggle_transparency, nor)

-- float

-- map("n", "<leader>ss", ":e .projections.json<cr>", {})

map("n", "<leader>sm", function()
  -- require('utils.lua.float').toggle('Makefile', { height = 40, width = 100 })
  require("utils.lua.float").toggle("Makefile")
end, desc("Open Makefile file in a floating window"))

map("n", "<leader>sp", function()
  require("utils.lua.float").toggle("package.json")
end, desc("Open package.json file in a floating window"))

map("n", "<leader>se", function()
  require("utils.lua.float").toggle("../.envrc", { width = 80, height = 50 })
end, desc("Open .envrc file in a floating window"))

map(
  "n",
  "<leader>sP",
  "<cmd>lua require('utils.lua.float').toggle('.projections.json')<cr>",
  desc("Open .projections.json file in a floating window")
)

map(
  "n",
  "<leader>sr",
  "<cmd>lua require('utils.lua.float').toggle('requirements.txt')<cr>",
  desc("Open requirements.txt file in a floating window")
)

map(
  "n",
  "<leader>sc",
  "<cmd>lua require('utils.lua.float').toggle('Cargo.toml')<cr>",
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

map({ "n", "v" }, "<cr>", "za")
map({ "n", "v" }, "<s-cr>", "zA")
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    map({ "n", "v" }, "<CR>", "<CR>", { buffer = true })
  end,
})

-- for command line window
vim.api.nvim_create_autocmd("CmdwinEnter", {
  callback = function()
    map({ "n", "v" }, "<CR>", "<CR>", { noremap = true, buffer = true })
    map({ "n", "v" }, "<C-c>", "<C-c>", { noremap = true, buffer = true })
  end,
})

map("n", "<c-l><c-l>", ":nohl<cr>")

-- color picker
map("n", "<leader>,C", "<cmd>PickColor<cr>", nor)

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

require("keybindings.Sbindings")

-- treesitter
-- Press o to show the query editor. Write your query like (node) @capture, put the cursor under the capture to highlight the matches.
map({ "n", "x" }, "<leader>,ti", "<cmd>Inspect<CR>")
map({ "n", "x" }, "<leader>,tt", "<cmd>InspectTree<CR>")
map({ "n", "x" }, "<leader>,te", "<cmd>EditQuery<CR>")
vim.api.nvim_create_autocmd("FileType", {
  pattern = "query",
  callback = function()
    map({ "n", "x" }, "<s-cr>", "<cmd>EditQuery<CR>", { buffer = true })
  end,
})

vim.cmd([[command! -nargs=+ Put :put=execute('<args>')]])

-- [d for prev diagnostics
-- ]d for next diagnostics
map("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<cr>", nor)
map("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<cr>", nor)

map("n", "<Del>", "<cmd>lua vim.diagnostic.goto_next()<cr>", nor)
map("n", "<S-Del>", "<cmd>lua vim.diagnostic.goto_prev()<cr>", nor)

map("n", "<leader><leader>x", "<cmd>luafile %<cr>", nor)

require("keybindings.ai")
