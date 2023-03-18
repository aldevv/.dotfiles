vim.cmd([[
set nocompatible " disable compatibility to vi, to activate vim improvements
if executable('zsh')
  set shell=/bin/zsh
endif

filetype plugin indent on
filetype plugin on

set updatetime=1500 " this is for autosave in tex files(every cursorhold event)
set encoding=utf-8
set splitright
set splitbelow
set title
set titlestring=\ %{expand(\"%:p:~\")}%a%r%m
let g:yankring_clipboard_monitor=0
" set spelllang=en_us,es
let &t_8f = '\<esc>[38;2;%lu;%lu;%lum'
let &t_8b = '\<esc>[48;2;%lu;%lu;%lum'
set textwidth=95
set viewoptions=folds,cursor
set sessionoptions=folds
let g:extension = expand('%:e')

set list                              " show whitespace
set listchars=nbsp:⦸                  " CIRCLED REVERSE SOLIDUS (U+29B8, UTF-8: E2 A6 B8)
set listchars+=tab:▷┅                 " WHITE RIGHT-POINTING TRIANGLE (U+25B7, UTF-8: E2 96 B7)
                                      " + BOX DRAWINGS HEAVY TRIPLE DASH HORIZONTAL (U+2505, UTF-8: E2 94 85)
set listchars+=extends:»              " RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00BB, UTF-8: C2 BB)
set listchars+=precedes:«             " LEFT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00AB, UTF-8: C2 AB)
set listchars+=trail:•
set listchars+=eol:↲

set expandtab "always use spaces and not tabs
set noerrorbells
set ignorecase
set smartcase
set nowrap
set noswapfile
set incsearch
set relativenumber
set laststatus=0

" make backspaces more powerfull
set backspace=indent,eol,start

set cmdheight=1
" to  select and move cursor
set mouse=a
" to show stuff under the modeline
set noshowmode
" change buffers without saving
set hidden
" ask to save when not saved
set confirm

"detect root in git repo
if executable('rg')
  let g:rg_derive_root='true'
endif

let g:python3_host_prog = '/bin/python3'
let g:termdebug_popup = 0
let g:termdebug_wide = 163

]])

vim.o.guifont = "DaddyTimeMono Nerd Font,JoyPixels:h12"
vim.opt.exrc = true
-- https://vonheikemen.github.io/devlog/tools/configuring-neovim-using-lua/
-- neovide
vim.g.neovide_refresh_rate = 140
-- vim.g.neovide_transparency=1
--
-- vim.g.neovide_cursor_animation_length=0.13 -- in seconds
--let g:neovide_cursor_trail_length=0.8
-- vim.g.neovide_cursor_vfx_mode = "railgun" -- torpedo, pixiedust, sonicboom, ripple, wireframe
--vim.g.neovide_cursor_vfx_opacity=200.0 -- particle opacity
--vim.g.neovide_cursor_vfx_particle_density=7.0 -- particle density
--vim.g.neovide_cursor_vfx_particle_speed=10.0 -- particle speed
--vim.g.neovide_cursor_vfx_particle_phase=1.5 -- particle phase
--vim.g.neovide_cursor_vfx_particle_curl=1.0 -- particle curl

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
vim.o.undofile = true
vim.o.inccommand = "nosplit"
--Make backup before overwriting the current buffer
vim.o.writebackup = true
-- Overwrite the original backup file
vim.o.backupcopy = "no"
-- Meaningful backup name, ex: filename@2015-04-05.14:59
vim.cmd([[
    au BufWritePre * let &bex = "@" . strftime("%F.%H:%M")
]])
vim.o.backupdir = vim.fn.stdpath("cache") .. "/backups"
vim.o.undodir = vim.fn.stdpath("cache") .. "/undodir"
vim.o.autochdir = false -- for netrw

vim.opt.timeoutlen = 700
vim.opt.laststatus = 3
vim.opt.pumblend = 10
vim.opt.statusline = "%t"
-- uses nvim-navic
-- vim.o.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"
-- uncomment this in a future version, is buggy as of version 0.9 dev 15-11-22
-- vim.opt.cmdheight = 0
vim.opt.spell = true
vim.g.netrw_keepdir = 1
vim.g.netrw_localrmdir = "rm -r"

-- size of indent and << and >>
vim.opt.shiftwidth = 4

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
