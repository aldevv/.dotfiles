vim.cmd([[
filetype plugin on
set number nu
]])

-- split window will put the new window right of the current one
vim.opt.splitright = true
-- split window will put the new window below the current one
vim.opt.splitbelow = true
-- the title of the window will be set to the filepath
vim.opt.title = true
vim.opt.titlestring = "%{expand(\"%:p:~\")}%a%r%m"

-- maximum width of text that is inserted, after which the text is broken
vim.opt.textwidth = 95

-- save folds and cursor position
vim.opt.viewoptions = "folds,cursor"
vim.opt.sessionoptions = "folds,cursor"

-- enable trailing symbols eol symbol etc
vim.opt.list = true
vim.opt.listchars = "nbsp:⦸" -- CIRCLED REVERSE SOLIDUS (U+29B8, UTF-8: E2 A6 B8)
vim.opt.listchars = vim.opt.listchars + "tab:▷┅" -- WHITE RIGHT-POINTING TRIANGLE (U+25B7, UTF-8: E2 96 B7)
vim.opt.listchars = vim.opt.listchars + "extends:»" -- RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00BB, UTF-8: C2 BB)
vim.opt.listchars = vim.opt.listchars + "precedes:«" -- LEFT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00AB, UTF-8: C2 AB)
vim.opt.listchars = vim.opt.listchars + "trail:•"
vim.opt.listchars = vim.opt.listchars + "eol:↲"

-- expand tab to spaces
vim.opt.expandtab = true
-- enable smartcase when searching/substituting
vim.opt.smartcase = true
-- disable wrapping lines
vim.opt.wrap = false
-- disable swap files
vim.opt.swapfile = false
-- enable incremental search
vim.opt.incsearch = true
-- enable relative line numbers
vim.opt.relativenumber = true
-- make backspaces more powerfull
vim.opt.backspace = "indent,eol,start"
-- enable mouse support
vim.opt.mouse = "a"
-- confirm before exiting if there are unsaved changes
vim.opt.confirm = true
-- enable running exrc files in cwd
vim.opt.exrc = true

-- https://vonheikemen.github.io/devlog/tools/configuring-neovim-using-lua/
-- neovide
vim.o.guifont = "DaddyTimeMono Nerd Font,JoyPixels:h12"
vim.g.neovide_refresh_rate = 140

vim.o.grepprg = "rg --vimgrep --no-heading --smart-case"

-- netrw
vim.g.netrw_bufsettings = "noma nomod nu nowrap ro nobl" -- add line numbers
-- hide hidden files
vim.g.netrw_hide = 1
vim.g.netrw_winsize = "25%"
vim.g.netrw_banner = 0
-- for the help menu
vim.o.wildmenu = true
vim.o.wildmode = "full"
-- " set wildmode=longest,list,full

vim.o.backup = true
vim.o.backupdir = vim.fn.stdpath("cache") .. "/backups"
vim.o.undofile = true
vim.o.undodir = vim.fn.stdpath("cache") .. "/undodir"
vim.o.inccommand = "nosplit"
--Make backup before overwriting the current buffer
vim.o.writebackup = true
-- Overwrite the original backup file
vim.o.backupcopy = "no"
-- Meaningful backup name, ex: filename@2015-04-05.14:59
vim.cmd([[
    au BufWritePre * let &bex = "@" . strftime("%F.%H:%M")
]])
vim.o.autochdir = false -- for netrw

-- add vertical line
vim.o.colorcolumn = "100"
-- colorcolumn transparent

vim.opt.updatetime = 250
vim.opt.timeoutlen = 700
vim.o.termguicolors = true

vim.opt.shiftwidth = 2

vim.opt.pumblend = 10
vim.opt.statusline = "%t"
vim.opt.spell = true


-- general diagnostics
vim.diagnostic.config({
  virtual_text = {
    spacing = 2,
    severity_limit = "Warning",
  },
  -- update_in_insert has bug with cmp, ghost_text (from cmp) overlaps virual_text (from diagnostics)
  -- update_in_insert = true,
  update_in_insert = false,
  float = {
    -- source = "if_many",
    source = true,
  },
})

vim.opt.jumpoptions = "stack"
