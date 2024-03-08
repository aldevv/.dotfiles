-- " =====================
-- " Sweet Sweet FuGITive
-- " =====================
-- " vimdiff commnads
-- ""]c :        - next difference
-- "[c :        - previous difference
-- "do          - diff obtain
-- "dp          - diff put
-- "zo          - open folded text
-- "zc          - close folded text
-- ":diffupdate - re-scan the files for differences
-- " default diffopt
-- " set diffopt=internal,filler,closeoff

local s = { silent = true }
local nor = { noremap = true }
local e = { expr = true }
local s_e = vim.tbl_extend("keep", s, e)

local nor_s = vim.tbl_extend("keep", nor, s)
local nor_e = vim.tbl_extend("keep", nor, e)
local nor_e_s = vim.tbl_extend("keep", nor, e, s)

local desc = function(desc)
  return vim.tbl_extend("keep", nor_s, { desc = desc })
end

local descv = function(desc)
  return vim.tbl_extend("keep", nor, { desc = desc })
end

local map = vim.keymap.set

-- use d2o and d3o
map("n", "<leader>g ", ":G ", nor)
map("v", "<leader>gdi", ":diffget //3<CR>", nor)
map("v", "<leader>gdh", ":diffget //2<CR>", nor)

map("n", "<leader>gd<space>", ":Gvdiffsplit @~", descv("Gdiffsplit @~_"))
map("n", "<leader>gdd", ":Gvdiffsplit @~<cr>", descv("Gdiffsplit @~"))
map("n", "<leader>gdq", ":G difftool @~", descv("Gdiffsplit @~_"))
map("n", "<leader>gdv", ":Gvdiffsplit! @~<cr>", descv("Gdiffsplit @~"))

map("n", "gV", ":Gvdiffsplit! @~", descv("Gdiffsplit @~_"))
map("n", "gQ", ":G difftool @~", descv("diff to quickfix list"))

map("n", "gs", ":G<CR>", nor)
map("n", "<leader>gSs", ":G stash<CR>", nor)
map("n", "<leader>gSp", ":G stash pop<CR>", nor)
map("n", "<leader>gSa", ":G stash apply<CR>", nor)
map("n", "<leader>gSt", ":Telescope git_stash<CR>", nor)
map("n", "<leader>gi", ":G init<CR>", nor)
map("n", "<leader>gm", ":G mergetool<CR>", nor)

-- for this file
map("n", "<leader>g0<space>", ":0Gclog ", descv("git log current file <0Gclog>"))
map("n", "<leader>g0g", ":0Gclog<cr>", nor)
map("n", "<leader>g0G", ":G log --decorate=short --all %<cr>", nor)
map("n", "<leader>g0m", ":0Gclog! ", nor)
map("n", "<leader>g0M", ":G! log % ", nor)
map("n", "<leader>g0v", ":GV!<CR>", nor) -- only list commits current file

-- old way
map("n", "g0", ":0Gclog!<cr>", nor)
map("n", "<leader>gl0<space>", ":0Gclog ", descv("git log current file <0Gclog>"))
map("n", "<leader>gl0g", ":0Gclog!<cr>", nor)
map("n", "<leader>gl0G", ":G log --decorate=short --all %<cr>", nor)
map("n", "<leader>gl0m", ":0Gclog! ", nor)
map("n", "<leader>gl0M", ":G! log % ", nor)
map("n", "<leader>gl0v", ":GV!<CR>", nor) -- only list commits current file

map("n", "gC", ":G commit<CR>", nor)      -- only list commits current file

-- while in the git log you can do:
-- coo to checkout that commit!
-- O to open in new tab
-- o to open in split
-- p to preview
-- <cr> to enter commit
map("n", "<leader>glt", ":Telescope git_commits<CR>", descv("Telescope git log <Telescope git_commits>"))
map("n", "<leader>glg", ":G log --decorate=short<CR>", descv("G log <normal>"))
map("n", "<leader>glm", ":G log ", descv("G log _"))       -- you could do % to view log of file
map("n", "<leader>gl<space>", ":G log ", descv("G log _")) -- you could do % to view log of file

map("n", "<leader>glG", ":Gclog!<CR>", descv("Gclog <quickfix>"))
map("v", "<leader>glg", ":Gclog!<CR>", nor) -- works in visual mode

map("n", "<leader>gla", ":G log --decorate=short --all<CR>", nor)
map("n", "<leader>glo", ":G log --oneline --all<CR>", nor)

map("n", "<leader>glM", ":Gclog! ", descv("Gclog! _"))
map("v", "<leader>glm", ":Gclog! ", nor)
map("v", "<leader>gl<space>", ":Gclog! ", descv("Gclog! _"))

map("n", "<leader>gp", ":G push -u origin HEAD<cr>", descv("G push -u origin HEAD"))
map("n", "<leader>gP", ":G push --force-with-lease<cr>", descv("G push -f -u origin HEAD"))
map("n", "<leader>gL", ":G pull<CR>", desc("G pull"))

map("n", "<leader>gb", ":G blame<CR>", nor)
map("n", "<leader>gB", ":GBrowse<CR>", nor)
map("n", "<leader>ga", ":GWrite<CR>", nor)
map("n", "<leader>gcc", ":G! commit<CR>", descv("G! commit"))
map("n", "<leader>gc<space>", ":G! commit ", descv("G! commit _"))
map("n", "<leader>gco", ":Telescope git_branches<CR>", descv("Telescope git checkout<Telescope git_branches>"))
map("n", "<leader>gcO", ":G! checkout -<CR>", descv("git checkout previous<G checkout ->"))
map("n", "<leader>gr", ":Gread<CR>", nor)   -- use index
map("n", "<leader>gR", ":Gread -<CR>", nor) -- use commit
map("n", "<leader>gw", ":Gwrite<CR>", nor)
map("n", "<leader>ge", ":Gedit<CR>", nor)
map("n", "<leader>gs", ":Gsplit @~", nor)
map("n", "<leader>gv", ":Gvsplit @~", nor)

-- GV
-- o or <cr> on a commit to display the content of it
-- o or <cr> on commits to display the diff in the range
-- O opens a new tab instead
-- gb for :GBrowse
-- ]] and [[ to move between commits
-- . to start command-line with :Git [CURSOR] SHA à la fugitive
-- q or gq to close
map("n", "<leader>glvv", ":GV<CR>", nor)  -- other plugin to visualize repo, you can use visual mode too
map("n", "<leader>glv?", ":GV!<CR>", nor) -- location list fill
map("v", "<leader>glvv", ":GV<CR>", nor)  -- other plugin to visualize repo, you can use visual mode too
map("v", "<leader>glv0", ":GV!<CR>", nor) -- only list commits current file
map("v", "<leader>glv?", ":GV!<CR>", nor) -- location list fill

map("n", "<leader>gVv", ":GV<CR>", nor)   -- commit history
map("n", "<leader>gV0", ":GV!<CR>", nor)  -- commit history current file
map("v", "<leader>gVv", ":GV<CR>", nor)   -- other plugin to visualize repo, you can use visual mode too
map("v", "<leader>gV0", ":GV!<CR>", nor)  -- only list commits current file

map("n", "<leader>gv", ":Gvsplit @~", nor)
