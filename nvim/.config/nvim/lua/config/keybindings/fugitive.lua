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

local map = vim.api.nvim_set_keymap


map('n', '<leader>gdi', ':diffget //3<CR>', nor)
map('n', '<leader>gdh', ':diffget //2<CR>', nor)
map('n', '<leader>gdi', ':diffget //3<CR>', nor)
map('n', '<leader>gds', ':Gdiffsplit!<CR>', nor)
map('n', '<leader>gdv', ':Gvdiffsplit!<CR>', nor)
map('n', '<leader>gdd', ':difftool<CR>', nor)
map('n', '<leader>gM', ':mergetool<CR>', nor)

map('n', '<leader>gst', ':G<CR>', nor)
map('n', '<leader>gi', ':G init<CR>', nor)
map('n', '<leader>ggc', ':G commit<CR>', nor)
map('n', '<leader>gm', ':G merge<CR>', nor)

map('n', '<leader>glg', ':Gclog<CR>', nor)
map('n', '<leader>ggp', ':G push<CR>', nor)
map('n', '<leader>ggP', ':G pull<CR>', nor)
map('n', '<leader>gb', ':G blame<CR>', nor)
map('n', '<leader>gB', ':GBrowse<CR>', nor)
map('n', '<leader>gaa', ':GWrite<CR>', nor)
map('n', '<leader>gc', ':G checkout<CR>', nor)
map('n', '<leader>gC', ':Gread<CR>', nor)

