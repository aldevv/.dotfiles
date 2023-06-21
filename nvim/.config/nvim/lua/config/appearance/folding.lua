-- =========
-- FOLDING
-- =========
vim.o.foldmethod = "expr"
vim.o.foldexpr = "nvim_treesitter#foldexpr()"
vim.o.foldlevel = 20
vim.o.foldenable = true

vim.cmd([[
let blacklist = ['org']
augroup remember_folds
  autocmd!
  au BufWinLeave ?* if index(blacklist, &ft) < 0 | mkview 1 | endif
  au BufWinEnter ?* if index(blacklist, &ft) < 0 | silent! loadview 1 | endif
augroup END
]])

-- NOTE: check foldopen in the options.txt for options on how to open a fold
vim.cmd([[
set foldopen =hor,search,tag,undo,quickfix,percent,mark,insert

nnoremap <silent> zn :<c-u>call RepeatCmd('call NextClosedFold("j")')<cr>
nnoremap <silent> ze :<c-u>call RepeatCmd('call NextClosedFold("k")')<cr>
" for adding a count to NextClosedFold
function! RepeatCmd(cmd) range abort
    let n = v:count < 1 ? 1 : v:count
    while n > 0
        exe a:cmd
        let n -= 1
    endwhile
endfunction

function! NextClosedFold(dir)
    let cmd = 'norm!z'..a:dir
    let view = winsaveview()
    let [l0, l, open] = [0, view.lnum, 1]
    while l != l0 && open
        exe cmd
        let [l0, l] = [l, line('.')]
        let open = foldclosed(l) < 0
    endwhile
    if open
        call winrestview(view)
    endif
endfunction
]])

-- is line folded
-- let a = foldclosed(lnum)

-- get all folds

-- function! CollectFolds() abort
--   if !exists('g:folds')
--     let g:folds = []
--   endif
--   const line = line('.')
--   const end = foldclosedend(line)
--   if !exists('g:prev_end') " first one
--     let g:prev_end = end
--     call add(g:folds, [line, end])
--   elseif end isnot# g:prev_end " new fold
--     call add(g:folds, [line, end])
--     let g:prev_end = end
--   endif
-- endfunction
--
-- command! PrintFolds execute 'folddoclosed call CollectFolds()' | echo g:folds | unlet g:folds g:prev_end
