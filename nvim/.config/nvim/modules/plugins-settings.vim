if !empty(glob("$XDG_CONFIG_HOME/nvim/modules/themes.vim")) && empty($NOCOC)
    source $XDG_CONFIG_HOME/nvim/modules/themes.vim
endif
"=====
"COC
"=====
if !empty(glob("$XDG_CONFIG_HOME/nvim/modules/fzf.vim")) && empty($NOCOC)
    source $XDG_CONFIG_HOME/nvim/modules/fzf.vim
endif
"
if !empty(glob("$XDG_CONFIG_HOME/nvim/modules/coc.vim")) && empty($NOCOC)
    source $XDG_CONFIG_HOME/nvim/modules/coc.vim
endif


"------------------------------------------------------------------------------------
if !empty(glob("$XDG_CONFIG_HOME/nvim/modules/format.vim")) && empty($NOCOC)
    source $XDG_CONFIG_HOME/nvim/modules/coc.vim
endif



if !empty(glob("$XDG_CONFIG_HOME/nvim/modules/vimspector.vim")) && empty($NOCOC)
    source $XDG_CONFIG_HOME/nvim/modules/vimspector.vim
endif


if !empty(glob("$XDG_CONFIG_HOME/nvim/modules/neoterm.vim")) && empty($NOCOC)
    source $XDG_CONFIG_HOME/nvim/modules/neoterm.vim
endif


"========================
" VIM-BUJO
"========================
let g:bujo#window_width = 90
let g:bujo#todo_file_path = $HOME . "/.cache/bujo"
map <silent><leader><leader>g <Plug>(BujoGlobal)
map <silent><leader><leader>p <Plug>(BujoProject)
map <silent><leader><leader>P <Plug>(BujoPrivate)

map <M-,> <Plug>(BujoAddnormal)
imap <M-,> <Plug>(BujoAddinsert)
map <M-.> <Plug>(BujoChecknormal)
imap <M-.> <Plug>(BujoCheckinsert)

"========================
" VIM-PROJECTIONIST
"========================
"
" heuristics, for general files

function! SetProjections()
  let l:global_projection = $FILES . "/projections/global/.projections.json"
  let l:json = readfile(l:global_projection)
  let l:dict = projectionist#json_parse(l:json)
  call projectionist#append(getcwd(), l:dict)
endfunction
" when a projection is found
if filereadable($FILES . "/projections/global/.projections.json")
  autocmd User ProjectionistDetect :call SetProjections()
endif

"==========
"DOTENV
"==========
function! s:env(var) abort
  return exists('*DotenvGet') ? DotenvGet(a:var) : eval('$'.a:var)
endfunction

let db_url = s:env('DATABASE_URL')

