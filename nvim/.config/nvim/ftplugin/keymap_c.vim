function s:savenoformat() abort
  noautocmd w
  exec ':Topen | T qmk flash'
endfunction

map  <silent><leader>o :call <SID>savenoformat()<CR>
