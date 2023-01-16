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

map("n", "<leader>gdi", ":diffget //3<CR>", nor)
map("n", "<leader>gdh", ":diffget //2<CR>", nor)
map("n", "<leader>gdi", ":diffget //3<CR>", nor)
map("n", "<leader>gdd", ":Gdiff<CR>", nor)
map("n", "<leader>gdD", ":G! difftool @~", nor) -- vertical
map("n", "<leader>gdt", ":G! difftool<CR>", nor)
map("n", "<leader>gdm", ":G diff @~", nor)
map("n", "<leader>gds", ":Gdiffsplit! @~", nor)
map("n", "<leader>gdv", ":Gvdiffsplit! @~", nor)

map("n", "<leader>gs", ":G<CR>", nor)
map("n", "<leader>gS", ":Telescope git_stash<CR>", nor)
map("n", "<leader>gi", ":G init<CR>", nor)
map("n", "<leader>gm", ":G mergetool<CR>", nor)

map("n", "<leader>gl0", ":0Gclog!<cr>", nor)
map("n", "<leader>gl=", ":0Gclog! ", nor)
map("n", "<leader>glt", ":Telescope git_commits<CR>", nor)
map("n", "<leader>glg", ":Gclog!<CR>", nor)
map("n", "<leader>glG", ":Gclog! ", nor)
map("n", "<leader>glm", ":G! log ", nor)
map("n", "<leader>gp", ":G push<CR>", nor)
map("n", "<leader>gP", ":G push ", nor)
map("n", "<leader>gll", ":G pull<CR>", nor)
map("n", "<leader>glL", ":G pull ", nor)
map("n", "<leader>gb", ":G blame<CR>", nor)
map("n", "<leader>gB", ":GBrowse<CR>", nor)
map("n", "<leader>ga", ":GWrite<CR>", nor)
map("n", "<leader>gcc", ":G! commit<CR>", nor)
map("n", "<leader>gcC", ":G! commit ", nor)
map("n", "<leader>gco", ":Telescope git_branches<CR>", nor)
map("n", "<leader>gcO", ":G! checkout -<CR>", nor)
map("n", "<leader>gC", ":Gread<CR>", nor)

local wk = require("which-key")
wk.register({
    gc = {
        name = "git commit and checkout ",
        c = { "git commit <G commit>" },
        C = { "git commit manual <G commit>" },
        o = { "Telescope git checkout<Telescope git_branches>" },
        O = { "git checkout previous<G checkout ->" },
    },
    gp = {
        name = "git push",
        p = { "git push <G push>" },
        P = { "git push custom <G push>" },
    },
    gl = {
        name = "git log and pull",
        l = { "git pull <G pull>" },
        L = { "git pull custom <G pull>" },
        g = { "git log <Gclog!>" },
        G = { "git log custom <Gclog!>" },
        m = { "git log manual <G! log>" },
        t = { "Telescope git log <Telescope git_commits>" },
        ["0"] = { "git log current file <0Gclog>" },
        ["="] = { "git log current file custom <0Gclog>" },
    },
    gd = {
        name = "git diff",
        d = { "git diff split <Gdiff>" },
        D = { "git diff 3 split<Gdiff!>" },
        t = { "git diff <G difftool>" },
        D = { "git diff custom commit <G difftool @~>" },
        m = { "git diff manual <G diff @~>" },
        v = { "git diff vertical custom commit <Gvdiffsplit>" },
        s = { "git diff horizontal custom commit <Gdiffsplit>" },
    },
}, { prefix = "<leader>" })
