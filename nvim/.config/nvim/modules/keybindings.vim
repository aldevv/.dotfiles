" testing inclusiveness (these work)
" nnoremap db dvb
" nnoremap dB dvB
" colemak movement
" ---------------- -- putting this in lua, breaks targets.vim (because the order of sourcing)
" migrate targets.vim first then this
noremap n j
noremap e k
noremap j e
noremap gj ge
noremap gJ gE
nnoremap l i
nnoremap i l
vnoremap i l
noremap k nzzzv
noremap K Nzzzv
noremap ge gk
noremap gn gj
noremap gk gn
noremap gE gJ
" ----------------



" put last searched items into QuickFix window
nnoremap <leader>- :execute 'vimgrep /'.@/.'/g %'<cr>:copen<cr>



" move lines without clipboard
nnoremap <S-UP> :m .-2<cr>==
nnoremap <S-DOWN> :m .+1<cr>==
vnoremap <S-UP> :m '<-2<cr>gv=gv
vnoremap <S-DOWN> :m '>+1<cr>gv=gv

" vnoremap E :m '<-2<cr>gv=gv
" vnoremap N :m '>+1<cr>gv=gv
"
noremap J E

vnoremap L I


noremap N i<cr><esc>k$
vnoremap N : s/\n/ /g<cr>$x

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
" noremap <a-n> <c-n>
" noremap <a-e> <c-p>
" nnoremap <CR> o<Esc>
" nnoremap <S-CR> O<Esc>
" nnoremap [13;2u o

noremap - /
vnoremap - /
" noremap / -

" for folds
nnoremap <leader>Z zMzvzz

nnoremap <silent><leader>,n  :w !npm start 2>/dev/null<cr>
nnoremap <silent><leader>,ri  :w ! [ ! -e '.env' ] && python3 -m venv .venv 2>/dev/null; .venv/bin/pip3 install -r requirements.txt 2>/dev/null<cr>



let g:extension = expand('%:e')
" nnoremap <silent> <leader>z :call ToggleFMethod()<cr>
" function ToggleFMethod()
"   let method=&foldmethod
"   if method == "expr"
"     set foldmethod=manual
"   else
"     set foldmethod=expr
"   endif
" endfunction

" this didnt work because it needs to be put down lower, but is a good example
" of how to obtain input for a command
"
function! GetName(detail)
    call inputsave()
    let l:filename = input(a:detail)
    call inputrestore()
    return l:filename
endfunction

" function! GetNameDmenu(detail)
"   " call inputsave()
"   let l:filename = system('dmenu -p ' . shellescape(a:detail))
"   echo l:filename
"     " call inputrestore()
"     " return l:filename
" endfunction

" nnoremap <leader>Sd  :call GetNameDmenu("something")<cr>
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

  if !SpecialWindow()
    w
  endif

endfunction

nnoremap <silent><leader>sn  :silent call CreateFileEnter()<cr>
nnoremap <silent><leader>sN  :silent call CreateFileTouch()<cr>
nnoremap <silent><leader>sf  :silent call CreateDir()<cr>
" nnoremap <leader>sF  :call RemoveDir()<cr>
" nnoremap <leader>sN  :call RemoveFile()<cr>

" 'cd' towards the directory in which the current file is edited
" but only change the path for the current window
nnoremap <leader>sc :lcd %:h<CR>

" close buffers
noremap <leader>sd :bd<cr>

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

nnoremap <leader>p "+p
nnoremap <leader>P "+P
vnoremap <leader>p "+p
vnoremap <leader>P "+P
nmap <leader>gp "+gp
" copy default register into the main clipboard
" nnoremap <silent> <leader>. :let @+ = @"<cr>

"useful
nnoremap Y y$
nnoremap V v$
nnoremap gl gi
" nnoremap , ;
" nnoremap ; ,
nnoremap <leader>cct :!ctags -R<cr>



" noremap gss !python2 -c "import sys; print(sys.stdin.read())"<cr>
"https://stackoverflow.com/questions/40072761/vim-send-visual-block-to-external-command
"added B and S (vis plugin)
"B for applying commands to the visually selected area and only to that visual area
"S is for searching stuff ONLY in the visually selected area
vnoremap <silent><leader>lgs :B !sortList.py <cr>t]xT[
vnoremap <silent><leader>lgr :B !sortListR.py <cr>t]xT[


nnoremap gñ :SyntaxQuery<CR>
nnoremap <silent><leader>.T :silent call Toggle_transparent()<CR>
function! Toggle_transparent()
  exec ':!toggleTrans'
endfunction

" general insert commands
inoremap <a-m> <++>
"" Guide navigation
noremap <a-k> <Esc>/<++><Enter>"_c4l
inoremap <a-k> <Esc>/<++><Enter>"_c4l
vnoremap <a-k> <Esc>/<++><Enter>"_c4l


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
noremap  <Down> 5<c-w>-
noremap  <Up> 5<c-w>+
noremap  <Right> 5<c-w>>
noremap  <Left> 5<c-w><
" split movement , cant be <c-i> because that is mapped to be the opposite of <c-o>
" noremap <tab> %
" vnoremap <tab> %


" noremap <c-i> <c-i>
" set <tab>=^[
" noremap <TAB> <tab>


" nnoremap <leader>ss <c-w>s
" nnoremap <leader>sv <c-w>v

" map <leader>i :setlocal autoindent<cr>
" map <leader>I :setlocal noautoindent<cr>
map <a-o> :w<CR>
map <a-O> :w !sudo tee %<CR>

map  <silent><leader>O :silent w !sudo tee %<CR>
" map  <leader>ss :wq<CR>
" map <leader><F1> :e ~/.config/nvim/init.vim<cr>
nnoremap <F6> :e $HOME/.config/nvim/init.vim<cr>
map <leader><F2> :e ~/.zshrc<cr>
" noremap  <leader>ww :w<CR>
noremap  ! :!
noremap  <F7> :set spell! \| set wrap<CR>
noremap  <leader>Ts :set spell! \| set wrap<CR>

map ñ :

" Ctrl-O lets you do just one command in insert mode

inoremap <a-h> <Left>
" inoremap <C-n> <Down>
" inoremap <C-e> <Up>
inoremap <a-i> <Right>

cnoremap <a-h> <Left>
cnoremap <a-e> <Up>
cnoremap <a-n> <Down>
cnoremap <a-i> <Right>

" map <silent> <leader>RR :call Runner()<cr>
" autocmd FileType python map <silent> <cr> :call Runner()<cr>
" autocmd FileType python nnoremap <buffer> <s-cr> :silent w<bar>only<bar>vsp<bar>term ipython3 -i %<cr>
autocmd FileType python nnoremap <buffer> <s-cr> :silent w<bar>only<bar>vsp<bar>term jupyter console<cr> <c-w>l :JupyterConnect<cr><cr> :JupyterRunFile<cr>
autocmd FileType java nnoremap <silent><buffer> <s-cr> :silent w<bar>execute "!java ".expand('%:t:r')<cr>
noremap <silent><leader><cr> :silent call RunnerTerminal()<cr>
nnoremap <silent><cr> :silent call RunnerEnter()<cr>

function! SpecialWindow()
  return &buftype == 'quickfix' || &buftype == 'nofile'
endfunction

function! RunnerEnter()
  " if bufname('%') == '' || &buftype == 'quickfix' || &buftype == 'nofile'
  if SpecialWindow() || bufname('%') == ''
    silent execute "normal! \<CR>"
  else
    silent call Runner()
  endif
endfunction


" dispatch takes values from the global projections file
" /home/kanon/.local/share/myScripts/files/projections/global/.projections.json
function! Runner()
  exec 'silent w'
  let l:runner = 'Dispatch! '
  let l:special_cases = ['java', 'rs', 'go']
  if index(l:special_cases, g:extension) >= 0 " si esta en el arreglo
    let l:runner = 'Dispatch!'
  else
    let l:runner = 'Dispatch '
  endif
  silent execute l:runner
  execute 'Copen'
  execute "normal! \<c-w>k"
endfunction

function! RunnerTerminal()
  exec 'silent w'
  let l:runnerCommand = projectionist#query('dispatch')[0][1]
  let l:runner = 'T '
  execute l:runner . l:runnerCommand
  " execute "normal! \<c-w>k"
endfunction

" open browser in current file folder
map <silent> <leader>.r :silent call jobstart('setsid st -e ranger $(dirname %) 2>&1')<cr>
map <silent> <leader>.R :silent call jobstart('setsid st -e sudo ranger $(dirname %) 2>&1')<cr>
map <silent> <leader>.- :silent call jobstart('setsid st -e sudo nvim ' . expand('%:p') . ' "+normal ' . line('.') . 'G' . col('.') . '\|" 2>&1')<cr>
map <silent> <leader>.t :silent call jobstart('setsid st')<cr>
"old
" map <leader>ra :silent !setsid st -e ranger $(dirname %) 2>&1 &<cr>


"debugging python, needs pip install ipdb
func! s:SetBreakpoint()
  cal append('.', repeat(' ', strlen(matchstr(getline('.'), '^\s*'))) . 'import ipdb; ipdb.set_trace()')
endf

func! s:RemoveBreakpoint()
  exe 'silent! g/^\s*import\sipdb\;\?\n*\s*ipdb.set_trace()/d'
endf

func! s:ToggleBreakpoint()
  if getline('.')=~#'^\s*import\sipdb' | cal s:RemoveBreakpoint() | el | cal s:SetBreakpoint() | en
endf
" nnoremap <F6> :call <SID>ToggleBreakpoint()<CR>

"====================
" ABBREVIATIONS
"====================
autocmd FileType python,java,js,jsx,ts iabbrev <buffer> rrt return
autocmd FileType python,java,js,jsx,ts iabbrev <buffer> ffa False
autocmd FileType python,java,js,jsx,ts iabbrev <buffer> ttr True
autocmd FileType python,java,js,jsx,ts iabbrev <buffer> bbr Break

" use * in visual mode
function! s:VSetSearch()
  let temp = @@
  norm! gvy
  let @/ = '\V' . substitute(escape(@@, '\'), '\n', '\\n', 'g')
  let @@ = temp
endfunction

vnoremap * :<C-u>call <SID>VSetSearch()<CR>//<CR><c-o>
vnoremap # :<C-u>call <SID>VSetSearch()<CR>??<CR><c-o>
" map <silent><leader>,f :silent execute '!formatCode' shellescape(&ft)<cr>
nnoremap <leader>V V`]


" clear search highlights
noremap <silent><leader>HH :nohlsearch<bar>match none<bar>2match none<bar>3match none<Esc>
" nnoremap <silent><leader>hh :execute 'match DiffAdd /\<<c-r><c-w>\>/'<cr>
nnoremap <silent><leader>H1 :execute '3match IncSearch /\<<c-r><c-w>\>/'<cr>
nnoremap <silent><leader>H2 :execute '2match DiffChange /\<<c-r><c-w>\>/'<cr>
nnoremap <silent><leader>H3 :execute 'match DiffAdd /\<<c-r><c-w>\>/'<cr>

" to search only selected text with * and #
vnoremap * :<C-u>call <SID>VSetSearch()<CR>//<CR><c-o>
vnoremap # :<C-u>call <SID>VSetSearch()<CR>??<CR><c-o>

function! s:VSetSearch()
  let temp = @@
  norm! gvy
  let @/ = '\V' . substitute(escape(@@, '\'),'\n','\\n','g')
  let @@ = temp
endfunction

" GIST
" requires gist installed
" you need to do gist --login for the first time
vnoremap <leader>G :w !gist -p -t %:e \| xsel -b<cr>
nnoremap Q gqip
" to source your init.vim (only one line)
vnoremap <silent><leader>S y:execute @@<cr>
nnoremap <silent><leader>S ^vg_y:execute @@<cr>
noremap <leader>0 :Colors<cr>

vnoremap <silent><leader>ss y:lua <c-r>+<cr>
nnoremap <silent><leader>ss ^vg_y:lua <c-r>+<cr>

" help current word
" nnoremap gw :h <c-r>=expand('<cword>')<cr><bar>resize 15<cr>

" nnoremap <silent><leader>cp :silent call FormatMyCode()<cr>
nnoremap <silent><leader>cP :silent call FormatMyCode()<cr>
autocmd BufNewFile *.cpp,*.c,*.java call FormatMyCode()

function! FormatMyCode()
  execute '!$APPS/nvim/programming/formatCode ' . g:extension .' '. expand('%:p')
  if empty(getenv('NOCOC'))
    :CocRestart
  else
    :LspRestart
  endif
endfunction

cnoreabbrev Sne CocCommand snippets.editSnippets

" this is to exit select mode when using snips
snoremap <Esc> <c-c>

function! QuicktypeFunc(lang)
  normal mm
  let code = execute("!xclip -sel c -o | quicktype --lang " . a:lang)
  silent put =code
  normal! 'mjjdd
endfunction

command! -bang -nargs=? Quicktype call QuicktypeFunc(<q-args>)

