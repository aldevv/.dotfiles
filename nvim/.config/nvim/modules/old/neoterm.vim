" ================
" NEOTERM
" ================

let g:neoterm_size="20"
let g:neoterm_autoinsert = 1
let g:neoterm_default_mod = 'rightbelow'
let g:neoterm_automap_keys='¡tt'
let g:neoterm_keep_term_open = 0
tmap <silent><a-t> <C-\><C-n>
tmap <silent><a-d> <a-t><c-w>e
map <silent><a-q> :call Open_terminal()<CR>
tmap <silent><a-q> <a-t>:q<CR>
nnoremap <silent><a-d> :call Switch_terminal()<CR>

function! Open_terminal()

  " only the first time
  let exists_name = bufname("neoterm-*")
  if len(exists_name) == 0
    let project_root = git#find_current_root()
    exec ':botright T cd ' . project_root
    call chansend(b:terminal_job_id, "")"
    return
  endif
  " if closed, open it
  let exists = bufwinnr("neoterm-*")
  if exists == -1
    :botright Ttoggle<CR>
    return
  endif

  " if open but not focused on it
  let win = winnr()
  call utils#focus_window(exists)
  call chansend(b:terminal_job_id, '' . '')
  :q
endfunction

function! Switch_terminal()
  if &buftype == "terminal"
    exec "normal! \<c-w>k"
    return
  endif

  " let exists = bufwinnr("neoterm-*")
  " if exists == -1
  " FIRST TIME ONLY
  let exists_name = bufname("neoterm-*")
  if len(exists_name) == 0
    let project_root = git#find_current_root()
    exec ':botright T cd ' . project_root
    call chansend(b:terminal_job_id, "")"
    return
  endif

  let exists = bufwinnr("neoterm-*")
  if exists == -1
    :botright Ttoggle<CR>
    let exists = bufwinnr("neoterm-*")
  endif

  call utils#focus_window(exists)
    execute 'normal! a'
    " this is up key and escape
    call chansend(b:terminal_job_id, "OA" . "")
endfunction



