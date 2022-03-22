" markdown_bujo.vim - A minimalist todo list manager
" Maintainer:   Jersey Fonseca <http://www.jerseyfonseca.com/>
" Version:      0.5

" SearchCheck() searches for whether or not BujoCheck... was called on a
" checked or unchecked task. We need to call search() twice with and without
" the 'b' tag because search() only allows you to search forward or backwards,
" not both ways.

"ORIGINAL
" search() returns 0 if it the pattern was not found
" function <SID>SearchCheck()
"   return (search('\[\]', 'nc', line('.')) || search('\[\]', 'nbc', line('.')))
" endfunction

function s:SearchCheck()
" search string in current cursor pos and backwards for - character
  return (search('-', 'nc', line('.')) || search('-', 'nbc', line('.')))
endfunction

function s:SearchCheckBrackets()
" search string in current cursor pos and backwards for [] character
  return (search('\[\]', 'nc', line('.')) || search('\[\]', 'nbc', line('.')))
endfunction


" Edit markdown lists
" Add and remove bullets with ease
" If we are already checked then we uncheck
nnoremap <expr><silent><Plug>(BujoChecknormal) <SID>SearchCheckBrackets() ? 'mm:silent! .s/\[\]/\[x\]<Enter>`m<right>' : 'mm:silent! .s/\[x\]/\[\]<Enter>`m<left>'
inoremap <expr><silent><Plug>(BujoCheckinsert) <SID>SearchCheckBrackets() ? '<esc>mm:silent! .s/\[\]/\[x\]<Enter>`ma<right>' : '<esc>mm:silent! .s/\[x\]/\[\]<Enter>`ma<left>'

noremap <expr><Plug>(BujoAddnormal) <SID>SearchCheck() ? '' : 'i- [] '
inoremap <expr><Plug>(BujoAddinsert) <SID>SearchCheck() ? '' : '- [] '

" noremap <expr><buffer><Plug>(BujoAddnormal) <SID>SearchCheck() ? 'i[] ' : 'i- [] '
" inoremap <expr><buffer><Plug>(BujoAddinsert) <SID>SearchCheck() ? '[] ' : '- [] '

" nnoremap <silent> <buffer> <Plug>BujoAddnormal i-[]
" inoremap <silent> <buffer> <Plug>BujoAddinsert -[]
"
