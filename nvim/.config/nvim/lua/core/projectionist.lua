vim.cmd([[
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
]])
