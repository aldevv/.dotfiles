" unique is not obligatory
" :h <sid> , use it instead of s: in mappings definition
" in the vimrc IT HAS TO BE NMAP or equivalent, no noremap

" noremap <unique> <Plug>(InsertSkeleton) :silent call <SID>addSkel()<CR>
noremap <unique> <Plug>(InsertSkeleton) :call <SID>addSkel()<CR>

function! s:addSkel()
        " if exists('b:projectionist')
            " Loop through projections with 'skeleton' key
            " and try each one until the snippet expands
            for [root, value] in projectionist#query('skeleton')
                echo " got here!"
              if s:try_insert(value)
                call s:install_undo_workaround()
                return
              endif
            endfor
        if s:try_insert('skel')
            call s:install_undo_workaround()
        endif
endfunction

function! s:install_undo_workaround() abort
  nnoremap <buffer> u :call <SID>undo_workaround()<CR>
endfunction

function! s:undo_workaround() abort
  normal! 2u
  nunmap <buffer> u
endfunction

" for ultisnips
function! s:try_insert(skel)
  execute 'silent normal! i_' . a:skel . "\<C-r>=UltiSnips#ExpandSnippet()\<CR>"
  if g:ulti_expand_res == 0
    silent! undo
  endif
  return g:ulti_expand_res
endfunction

" for coc_snippets
" let g:snippet_expanded = 0
" function! s:try_insert(skel)
"     silent execute 'normal! i_' . a:skel . "\<C-r>=<sid>coc_expand()\<cr>"
"     if g:snippet_expanded == 0
"         silent! undo
"     endif
"     return g:snippet_expanded
" endfunction

" function! s:coc_expand()
"     if coc#expandable()
"         let g:snippet_expanded = 1
"         return coc#rpc#request('doKeymap', ['snippets-expand-jump',''])
"     endif
"     let g:snippet_expanded = 0
"     return
" endfunction
