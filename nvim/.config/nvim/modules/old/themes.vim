"==========
"Themes
"==========
"https://github.com/vim-airline/vim-airline/wiki/Screenshots
"
" let g:airline_theme='luna'
" let g:airline_theme='gruvbox'
"
set termguicolors
if exists('+termguicolors')
    set t_8f=\[[38;2;%lu;%lu;%lum
    set t_8b=\[[48;2;%lu;%lu;%lum
endif

set pumblend=15
" Theme
"colorscheme onehalfdark
"try codedark
"
"(gruvbox dracula monokai codedark ayu)

if empty(getenv('NOCOC'))
let color_options = {
            \ "gruvbox":0,
            \ "dracula":1,
            \ "monokai":2,
            \ "onehalfdark":3,
            \ "ayu":4,
            \}
" let current_colorscheme = color_options["ayu"]
let current_colorscheme = color_options["gruvbox"]

if current_colorscheme == 0
    let g:gruvbox_invert_selection = '0'
    let g:airline_theme='gruvbox'
    " let g:airline_theme='minimalist'
    "soft medium hard
let g:gruvbox_contrast_dark = "hard"
    " not sure what this does
    let g:gruvbox_improved_warnings = 1
    colorscheme gruvbox
    " fix colors for highlighting spelling mistakes
    autocmd ColorScheme gruvbox hi! SpellBad cterm=reverse ctermfg=214 ctermbg=235 gui=reverse guifg=#fabd2f guibg=#282828
endif

if current_colorscheme == 1
    colorscheme dracula
    let g:dracula_italic = 1
    let g:airline_theme='dracula'
endif

if current_colorscheme == 2
    colorscheme monokai
    let g:airline_theme='monokai'
    let g:monokai_term_italic = 1
    let g:monokai_gui_italic = 1
endif
if current_colorscheme == 3
    " colorscheme onehalflight
    colorscheme onehalfdark
    let g:airline_theme='onehalfdark'
    " lightline
    " let g:lightline = { 'colorscheme': 'onehalfdark' }
endif

if current_colorscheme == 4
    let ayu_comment_italic=0 " enable italic for comments
    let ayu_string_italic=0  " enable italic for strings
    let ayu_type_italic=1    " enable italic for types
    let ayu_keyword_italic=1 " enable italic for keywords
    " let ayucolor="light"  " for light version of theme
    " let ayucolor="mirage" " for mirage version of theme
    let ayucolor="dark"   " for dark version of theme
    let g:airline_theme='ayu'
    colorscheme ayu
endif
endif

set background=dark

"========
"AIRLINE
"========

let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#buffer_min_count = 1
if IS_MINE
  let g:airline_powerline_fonts = 1
endif
" let b:airline_disable_statusline = 1
" let g:airline_statusline_ontop = 1
"
" let g:airline#extensions#tabline#fnametruncate = 30
" let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline#extensions#tabline#formatter = 'short_path'
" let g:airline#extensions#tabline#fnamemod = ':p:~'
" let g:airline#extensions#tabline#fnamecollapse = 3
" autocmd Filetype java,javascript,python let g:airline#extensions#tabline#enabled = 1
  let g:airline_mode_map = {
      \ '__'     : '-',
      \ 'c'      : 'C',
      \ 'i'      : 'I',
      \ 'ic'     : 'I',
      \ 'ix'     : 'I',
      \ 'n'      : 'N',
      \ 'multi'  : 'M',
      \ 'ni'     : 'N',
      \ 'no'     : 'N',
      \ 'R'      : 'R',
      \ 'Rv'     : 'R',
      \ 's'      : 'S',
      \ 'S'      : 'S',
      \ ''     : 'S',
      \ 't'      : 'T',
      \ 'v'      : 'V',
      \ 'V'      : 'V',
      \ ''     : 'V',
      \ }


" choose one or the other, not both
" let g:airline#extensions#bufferline#enabled = 1
let g:airline#extensions#fugitiveline#enabled = 1


let g:airline#extensions#tagbar#enabled = 1
" see tagbar-statusline
" let g:airline#extensions#tagbar#flags = ''  (default)
"   let g:airline#extensions#tagbar#flags = 'f'
" let g:airline#extensions#tagbar#flags = 's'
" let g:airline#extensions#tagbar#flags = 'p'

let g:airline#extensions#tagbar#flags = 'p'
let g:airline#extensions#obsession#enabled = 1
let g:airline#extensions#fzf#enabled = 1
let g:airline#extensions#coc#enabled = 1
let g:airline#extensions#virtualenv#enabled = 1

" let g:airline_section_c = airline#section#create(['%{expand("%:p:~")}', 'virtualenv'])
" has to be empty to show coc
" let g:airline_section_c = ''
" let g:airline_section_c = '%{expand("%:p:h:t")}/%t'
"
" let g:airline_section_c = '%<%<%{airline#extensions#fugitiveline#bufname()}%m %#__accent_red#%{airline#util#wrap(airline#parts#readonly(),0)}%#__restore__#%#__accent_bold#%{airline#util#wrap(airline#extensions#coc#get_status(),0)}%#__restore__#%#__accent_bold#%#__restore__#'

" you can check the value of these variables by: echo g:airline_section_x
let g:airline_section_c = '%<%<%m %#__accent_red#%{airline#util#wrap(airline#parts#readonly(),0)}%#__restore__#%#__accent_bold#%{airline#util#wrap(airline#extensions#coc#get_status(),0)}%#__restore__#%#__accent_bold#%#__restore__#'
" let g:airline_section_c=''
" remove separators for empty sections

" set title titlestring=%{expand('%:p:h:t')}/%t

" let g:airline#extensions#default#layout = [
"   \ [ 'a', 'b', 'c'],
    " \ [ 'x', 'y', 'z', 'error', 'warning' ]
      " \ ]

" autocmd Filetype python let g:airline#extensions#tabline#enabled = 1
"

