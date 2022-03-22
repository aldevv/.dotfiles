set nocompatible " disable compatibility to vi, to activate vim improvements
if executable('zsh')
  set shell=/bin/zsh
endif

filetype plugin indent on
filetype plugin on

set updatetime=1500 " this is for autosave in tex files(every cursorhold event)
set encoding=utf-8
scriptencoding utf-8
set splitright
set splitbelow
set title
  set titlestring=\ %{expand(\"%:p:~\")}%a%r%m
let g:yankring_clipboard_monitor=0
set spelllang=en_us,es
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

set wildmode=longest,list,full
set expandtab "always use spaces and not tabs
set noerrorbells
set ignorecase
set smartcase
set tabstop=4 softtabstop=4
set shiftwidth=4
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

let g:python_host_prog = '/usr/bin/python'
let g:python3_host_prog = '/usr/bin/python3'
let g:termdebug_popup = 0
let g:termdebug_wide = 163

" share registers between vim instances
augroup SHADA
  autocmd!
  autocmd CursorHold,TextYankPost,FocusGained,FocusLost *
        \ if exists(':rshada') | rshada | wshada | endif
augroup END

" if quickfix or terminal window is the last window, then close vim
aug QFClose
  au!
  au WinEnter * if winnr('$') == 1 && &buftype == "quickfix"|q|endif
  au WinEnter * if winnr('$') == 1 && &buftype == "terminal"|q|endif
aug END
