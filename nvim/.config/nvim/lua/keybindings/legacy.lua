vim.cmd [[
noremap gj ge
noremap gJ gE
noremap gn gj
noremap gN gJ
noremap k nzzzv
" for select mode
snoremap k k
noremap K Nzzzv
noremap gj ge
noremap gJ gE
noremap + K
" ----------------



" put last searched items into QuickFix window
nnoremap <leader>- :execute 'vimgrep /'.@/.'/g %'<cr>:copen<cr>



" move lines without clipboard
nnoremap <S-UP> :m .-2<cr>==
nnoremap <S-DOWN> :m .+1<cr>==
vnoremap <S-UP> :m '<-2<cr>gv=gv
vnoremap <S-DOWN> :m '>+1<cr>gv=gv
"
noremap J E

vnoremap L I


" gN is free
noremap ' `
" testing
noremap I L
nnoremap L I

noremap <c-w>N <c-w>J
noremap <c-w>E <c-w>K
noremap <c-w>I <c-w>L

noremap <c-w>n <c-w>j
noremap <c-w>e <c-w>k
noremap <c-w>i <c-w>l

noremap <c-w>k <c-w>n

nnoremap º <c-^>
" vertical version of <c-w>^
noremap <silent><c-w>º :vsp #<cr>
noremap <silent><c-w>V :vsp #<cr>
noremap <silent><c-w>S :sp #<cr>

noremap - /
vnoremap - /

" for folds
nnoremap <leader>Z zMzvzz

let g:extension = expand('%:e')
"
function! GetName(detail)
    call inputsave()
    let l:filename = input(a:detail)
    call inputrestore()
    return l:filename
endfunction


function! CreateFileTouch()
  let l:filename = GetName('Enter File Name: ')
  if len(l:filename) == 0
      return
  endif

  if l:filename =~ '\v.*/.+'
    exec system('cd ' . expand("%:p:h") . '; filename=' . l:filename . '; mkdir -p ${filename%\/*}/')
  endif

  exe ':!touch '. expand('%:p:h'). '/' . l:filename
  if !SpecialWindow()
    w
  endif
endfunction

function! CreateFileEnter()
  let l:filename = GetName('Enter File Name: ')
  if len(l:filename) == 0
      return
  endif

  if l:filename =~ '\v.*/.+'
    exec system('cd ' . expand("%:p:h") . '; filename=' . l:filename . '; mkdir -p ${filename%\/*}/')
  endif

  exe ':e '. expand('%:p:h'). '/' . l:filename
endfunction

function! CreateDir()
  let l:dir_name = GetName('Enter Dir Name: ')
  if len(l:dir_name) == 0
      return
  endif
  exe ':!mkdir -p '. expand('%:p:h'). '/' . l:dir_name

  if !&buftype == 'quickfix' || &buftype == 'nofile'
    w
  endif

endfunction

" close buffers
" noremap <leader>sD :bd<cr>

" change buffers like vscode
" noremap <silent>E :bprevious<cr>
" noremap <silent>N :bnext<cr>

" clipboard
" "*p pastes what is highlighted by the mouse
" ""p and "0p are the default registers
"
"diffput
vnoremap <leader>,p "_dP
" set clipboard=unnamedplus
vnoremap  <leader>y  "+y
nnoremap  <leader>Y  "+y$
nnoremap  <leader>y  "+y

vnoremap  <leader>d  "+d
nnoremap  <leader>D  "+d$
nnoremap  <leader>d  "+d

vnoremap  <leader>c  "+c
nnoremap  <leader>C  "+c$
nnoremap  <leader>c  "+c

vnoremap  <leader>x  "_d

nnoremap <leader>p "+p
nnoremap <leader>P "+P
vnoremap <leader>p "+p
vnoremap <leader>P "+P
" nmap <leader>gp "+gp

" copy default register into the main clipboard
" nnoremap <silent> <leader>. :let @+ = @"<cr>

"useful
nnoremap Y y$
nnoremap gl gi



" noremap gss !python2 -c "import sys; print(sys.stdin.read())"<cr>
"https://stackoverflow.com/questions/40072761/vim-send-visual-block-to-external-command
"added B and S (vis plugin)
"B for applying commands to the visually selected area and only to that visual area
"S is for searching stuff ONLY in the visually selected area
vnoremap <silent><leader>lgs :B !sortList.py <cr>t]xT[
vnoremap <silent><leader>lgr :B !sortListR.py <cr>t]xT[


nnoremap gñ :SyntaxQuery<CR>

" general insert commands

"global do
" not working in lua KEEP IT
"-----------------------

nnoremap <leader>.vS :%s/<c-r>=expand("<cword>")<cr>//gI<Left><Left><Left>
" nnoremap <leader>.vs :%s///gI<Left><Left><Left><Left>
nnoremap <leader>.vs :%s/
vnoremap <leader>.vs :s///gI<Left><Left><Left><Left>
nnoremap <leader>.vg :%g//norm!<Left><Left><Left><Left><Left><Left>
nnoremap <leader>.vn :%norm!<space>
vnoremap <leader>.vg :g//norm!<Left><Left><Left><Left><Left><Left>
"-----------------------
" save with no permission using w!!, could be cnoremap
nnoremap <silent><leader>.ch  :w !sudo chmod +x %<cr>
nnoremap <silent><leader>.co  :w !sudo chown $USER:$USER % 2>/dev/null<cr>
map <silent> <F11> /\A\zs\a<cr>
" split movement , cant be <c-i> because that is mapped to be the opposite of <c-o>
" noremap <tab> %
" vnoremap <tab> %


" noremap <c-i> <c-i>
" set <tab>=^[
" noremap <TAB> <tab>



map <a-o> :w<CR>
map <a-O> :w !sudo tee %<CR>

" map <leader><F1> :e ~/.config/nvim/init.vim<cr>
nnoremap <F6> :e $HOME/.config/nvim/init.lua<cr>
map <leader><F2> :e ~/.zshrc<cr>
" noremap  <leader>ww :w<CR>

noremap  <F7> :set spell! \| set wrap<CR>


" Ctrl-O lets you do just one command in insert mode

inoremap <a-h> <Left>
" inoremap <C-n> <Down>
" inoremap <C-e> <Up>
inoremap <a-i> <Right>

cnoremap <a-h> <Left>
cnoremap <a-e> <Up>
cnoremap <a-n> <Down>
cnoremap <a-i> <Right>





" dispatch takes values from the global projections file
" /home/kanon/.local/share/myScripts/files/projections/global/.projections.json



"====================
" ABBREVIATIONS
"====================
" clear search highlights
noremap <silent><leader>H :nohlsearch<bar>match none<bar>2match none<bar>3match none<Esc>

vnoremap <silent><leader>.ss y:lua <c-r>+<cr>
nnoremap <silent><leader>.ss ^vg_y:lua <c-r>+<cr>

function! Left()
  let line = getcmdline()
  let pos = getcmdpos()
  let next = 1
  let nextnext = 1
  let i = 2
  while nextnext < pos
    let next = nextnext
    let nextnext = match(line, '\<\S\|\>\S\|\s\zs\S\|^\|$', 0, i) + 1
    let i += 1
  endwhile
  return repeat("\<Left>", pos - next)
endfunction

function! Abstract_right(command)
  let line = getcmdline()
  let pos = getcmdpos()
  let next = 1
  let i = 2
  while next <= pos && next > 0
    let next = match(line, '\<\S\|\>\S\|\s\zs\S\|^\|$', 0, i) + 1
    let i += 1
  endwhile
  return repeat(a:command, next - pos)
endfunction

function! Right()
  return Abstract_right("\<Right>")
endfunction

" move by words in the command mode
cnoremap <expr> <M-w> Right()
cnoremap <expr> <M-b> Left()


]]
