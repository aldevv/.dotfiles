-- =========
-- FOLDING
-- =========
vim.o.foldmethod = "expr"
vim.o.foldexpr = "nvim_treesitter#foldexpr()"
vim.o.foldlevel = 20
vim.o.foldenable = true

vim.cmd [[
let blacklist = ['org', 'OverseerList']
augroup remember_folds
  autocmd!
  au BufWinLeave ?* if index(blacklist, &ft) < 0 | mkview 1 | endif
  au BufWinEnter ?* if index(blacklist, &ft) < 0 | silent! loadview 1 | endif
augroup END
]]

-- go to next and prev fold
vim.cmd [[
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
]]
