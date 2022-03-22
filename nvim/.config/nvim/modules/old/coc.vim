"===========
" COC-FZF
" ==========
" you can fill quickfix window with multiselect
let g:coc_fzf_preview_toggle_key = ''
let g:coc_fzf_preview = 'up:50%:hidden'
let g:coc_fzf_opts = []

"to make the command same as other fzf commands
" let g:coc_fzf_preview = ''

nnoremap <silent> <leader><space>a :<C-u>CocFzfList<CR>
nnoremap <silent> <leader><space>cd       :<C-u>CocFzfList diagnostics<CR>
nnoremap <silent> <leader><space>cD       :<C-u>CocFzfList diagnostics --current-buf<CR>
nnoremap <silent> <leader><space>cm       :<C-u>CocFzfList commands<CR>
nnoremap <silent> <leader><leader>ce       :<C-u>CocFzfList extensions<CR>
nnoremap <silent> <leader><space>cl       :<C-u>CocFzfList location<CR>
" nnoremap <silent> <leader>cv        :<C-u>CocFzfList outline<CR>
" nnoremap <silent> <a-n>            :<C-u>CocFzfList outline<CR>
nnoremap <silent> <leader><space>cS       :<C-u>CocFzfList sources<CR>
nnoremap <silent> <leader><space>cs       :<C-u>CocFzfList symbols<CR>
nnoremap <silent> <leader>cS       :<C-u>CocFzfList sources<CR>
nnoremap <silent> <leader>cs       :<C-u>CocFzfList symbols<CR>
nnoremap <silent> <leader><space>cL       :<C-u>CocFzfListResume<CR>

"=====
"COC
"=====

nmap <silent><leader>ccf <Plug>(coc-format)
highlight CocErrorHighlight ctermfg=Red  guifg=#ff0000
" \ 'coc-html',
" \ 'coc-json',
" \ 'coc-pairs',
" \ 'coc-tslint-plugin',
" \ 'coc-prettier',
" \ 'coc-ultisnips',
" \ 'coc-yaml',
" for docker compose add to coc-settings
"
            " \ 'coc-python',
let g:coc_global_extensions = [
            \ 'coc-pyright',
            \ 'coc-marketplace',
            \ 'coc-java-debug',
            \ 'coc-cssmodules',
            \ 'coc-json',
            \ 'coc-tag',
            \ 'coc-vimtex',
            \ 'coc-snippets',
            \ 'coc-tsserver',
            \ 'coc-css',
            \ 'coc-vimlsp',
            \ 'coc-lua',
            \ 'coc-sh',
            \ 'coc-diagnostic',
            \ 'coc-java',
            \ 'coc-clangd',
            \ 'coc-rls',
            \ 'coc-go',
            \ 'coc-yaml',
            \ 'coc-docker',
            \ ]
" coc-clangd is necessary for c and c++
nmap <silent> <leader>cci :CocInfo<cr>
nmap <silent> <leader>cC  :CocConfig<cr>
nmap <silent> <leader>ccC :CocLocalConfig<cr>
" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gD :vsp<CR><Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gY <Plug>(coc-type-declaration)
nmap gr <Plug>(coc-references)
nmap gR <Plug>(coc-references-used)
nmap gi <Plug>(coc-implementation)
" nmap <silent> <leader>cp <Plug>(coc-format)
" g{ and g} are usable
nnoremap <silent><nowait> <leader>cd  :<C-u>CocDiagnostics<cr>
" nmap ; <Plug>(coc-diagnostic-prev)
" nmap , <Plug>(coc-diagnostic-next)
nmap <silent> g; <Plug>(coc-diagnostic-prev-error)
nmap <silent> g, <Plug>(coc-diagnostic-next-error)
nmap <silent> g. <Plug>(coc-fix-current)
nnoremap <silent> +  :call CocAction('definitionHover')<cr>
" alt + -
inoremap <silent> <a--> <C-\><C-O>:call CocActionAsync('showSignatureHelp')<cr>

nmap <F2> <Plug>(coc-rename)
nmap cr :CocSearch <C-R>=expand('<cword>')<cr>
nmap cR :CocSearch <C-R>=expand('<cword>')<cr><cr>

":CocRebuild                        *:CocRebuild*
" use when you upgrade nodejs

nmap <leader>cl <Plug>(coc-codelens-action)
nnoremap <silent><nowait> <leader>cL  :<C-u>CocOpenLog<CR>
nmap <leader>+ <Plug>(coc-diagnostic-info)
" nmap <leader>* <Plug>(coc-fix-current)
nmap <leader>cA <Plug>(coc-codeaction)
nmap <leader>ca <Plug>(coc-codeaction-line)
vmap <leader>ca <Plug>(coc-codeaction-selected)
nmap <M-BS> <Plug>(coc-codeaction)
nmap <M-S-BS> <Plug>(coc-codeaction-line)
vmap <M-BS> <Plug>(coc-codeaction-selected)
nmap <silent><leader>cr <Plug>(coc-refactor)
cnoreabbrev CS CocSearch
" for static hover glitch
nnoremap <silent><esc> :call coc#float#close_all()<cr>


" or do <c-w>o to close it but it closes other windows as well

" nnoremap <silent> <leader>cs :call CocAction('documentSymbols')<cr>
" Mappings for CoCList
" Show all diagnostics.
nnoremap <silent><nowait> <leader>ccd  :<C-u>CocList diagnostics<cr>
" Do default action for next item.
nnoremap <silent><nowait> <leader>cn  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent><nowait> <leader>ce  :<C-u>CocPrev<CR>
nnoremap <silent><nowait> <leader>cR  :<C-u>CocRestart<cr>
nnoremap <silent><nowait> <leader>cM  :<C-u>CocList marketplace<CR>
nnoremap <silent><nowait> <leader>cm  :<C-u>CocList commands<CR>
nnoremap <silent><nowait> <leader>cv  :<C-u>CocList --auto-preview outline<cr>

" implemented in coc-fzf
" Find symbol of current document.
" nnoremap <silent><nowait> <leader>ccl  :<C-u>CocListResume<CR>
" nnoremap <silent><nowait> <leader>cce  :<C-u>CocList extensions<cr>
" nnoremap <silent><nowait> <leader>cs  :<C-u>CocList -I symbols<cr>
" Show commands.
" nnoremap <silent><nowait> <leader>ccc  :<C-u>CocList commands<cr>

" scroll documentation
" nnoremap <nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
" nnoremap <nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
"
" noremap <M-C-N> <c-e>
" noremap <M-C-E> <c-y>
noremap <silent><nowait><expr> <M-C-N> coc#float#has_scroll() ? ":call coc#float#scroll(1, 3)\<cr>" : "\<c-e>"
noremap <silent><nowait><expr> <M-C-E> coc#float#has_scroll() ? ":call coc#float#scroll(0, 3)\<cr>" : "\<c-y>"
inoremap <silent><nowait><expr> <M-C-N> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1, 3)\<cr>" : "\<c-o><c-e>"
inoremap <silent><nowait><expr> <M-C-E> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0, 3)\<cr>" : "\<c-o><c-y>"
" inoremap <silent><nowait><expr> <M-C-N> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1, 3)\<cr>" : "\<c-o><c-e>"
" inoremap <silent><nowait><expr> <M-C-E> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0, 3)\<cr>" : "\<c-o><c-y>"

" _______________________________________________
"
" CocSearch is very powerful, so you should use it with the many options it has available
" more info in man rg
"
"   `-F` `--fixed-strings`: treat search pattern as fixed string.
"    `-e` `--regexp`: treat search pattern as regexp.
"   `-L` `--follow`: follow symbolic links while traversing directories.
"   `-g` `--glob` {GLOB}: Include or exclude files and directories for
"   searching that match the given glob.
"   `--hidden`: Search hidden files and directories.
"   `--no-ignore-vcs`:  Don't respect version control ignore files
"   (.gitignore, etc.).
"   `--no-ignore`: Don't respect ignore files (.gitignore, .ignore, etc.).
"   `-w` `--word-regexp`: Only show matches surrounded by word boundaries.
"   `-S` `--smart-case`: Searches case insensitively if the pattern is all
"   lowercase. Search case sensitively otherwise.
"   `--no-config`: Never read configuration files.
"   `-x` `--line-regexp`: Only show matches surrounded by line boundaries.


function s:show_hover_doc()
    if matchstr(getline('.'), '\%' . col('.') . 'c.') =~ "\\S"
        silent! call timer_start(1300, 'ShowDocIfNoDiagnostic')
    endif
endfunction

function! ShowDocIfNoDiagnostic(timer_id)
    if (coc#float#has_float() == 0)
        " silent! call CocActionAsync('doHover')
        " non async so it doesnt try to create another one once theres already a rendered one
        silent! call CocAction('doHover')
    endif
endfunction

function Activate_hover()
    " autocmd CursorHoldI * silent! call <SID>show_hover_doc()
    autocmd CursorHold  * silent! call<SID>show_hover_doc()
    " autocmd CursorHold * if ! coc#float#has_float() | silent! call CocActionAsync('doHover') | endif
endfunction

" auto hover, uncomment for enabling
" augroup auto_hovering
"     autocmd!
"     autocmd FileType python,cpp,javascript,c,java :call Activate_hover()
" augroup END


" nnoremap <nowait><expr> <a-e> coc#util#float_scrollable() ? coc#util#float_scroll(0) : "\<c-w>\<c-v>"
nnoremap <nowait><expr><a-n> coc#float#has_scroll() ? coc#float#scroll(1) : OutlineFZF()
nnoremap <nowait><expr><a-e> coc#float#has_scroll() ? coc#float#scroll(0) : BrowseDots()

imap <silent><expr> <a-n> pumvisible() ? "\<C-n>" : "\<C-o>n"
imap <silent><expr> <a-e> pumvisible() ? "\<C-p>" : "\<C-o>e"



function OutlineFZF()
  return ":CocFzfList outline \<cr>"
endfunction

function BrowseDots()
" return ":FilesDots \<cr>"
    return ":\<C-u>TagbarToggle\<CR>"
endfunction


let g:coc_force_debug = 1
" Use c-n for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.

" inoremap <silent><expr> <C-n>
"    \ pumvisible() ? "\<C-n>" :
"    \ <SID>check_back_space() ? "\<TAB>" :
"    \ coc#refresh()

" inoremap <expr><C-e> pumvisible() ? "\<C-p>" : "\<C-h>"

" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
"
"this one lets you use tab to open popup menu when character before cursor
" inoremap <silent><expr> <TAB>
"    \ pumvisible() ? "\<C-n>" :
"    \ <SID>check_back_space() ? "\<TAB>" :
"    \ coc#refresh()

" inoremap <silent><expr> <TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
" inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
" inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

inoremap <silent><expr> <CR> pumvisible() && coc#rpc#request('hasSelected', []) ? "\<C-y>" : "\<CR>"

autocmd FileType python call PythonMappings()

function PythonMappings()
    map <leader>Lp :CocCommand python.setInterpreter<cr>
    map <leader>Lr :CocCommand python.execInTerminal<cr>
    map <leader>Ll :CocCommand python.setLinter<cr>
    map <leader>Lg :CocCommand python.viewOutput<cr>
endfunction
" call coc#config('python', {
"  \   'jediEnabled': v:false,
"  \   'pythonPath': split(execute('!which python3'), '\n')[-1]
"  \ })
"
" call coc#config('python', {
              " \ 'formatting.blackPath': $HOME."/.local/bin/black",
            " \})
            " \ 'linting.pylintPath': "usr/bin/pylint"



"=============
"COC-SNIPPETS
"=============
au BufRead,BufNewFile .vimspector.json		set filetype=vimspector.json
"gives me preview of the snippets, and gives me a shortcut to transform snippets quick
"
" Use <leader>x for convert visual selected code to snippet
xmap <leader>cx <Plug>(coc-convert-snippet)

nmap <leader>cx :CocCommand snippets.editSnippets<cr>

" these aren't used

" Use <C-l> for trigger snippet expand.
" imap <c-j> <Plug>(coc-snippets-expand)

" Use <C-j> for select text for visual placeholder of snippet.
vmap <a-t> <Plug>(coc-snippets-select)

" Use <C-j> for jump to next placeholder, it's default of coc.nvim
let g:coc_snippet_next = '<a-t>'

" Use <C-k> for jump to previous placeholder, it's default of coc.nvim
let g:coc_snippet_prev = '<a-s>'

" Use <a-t> for both expand and jump (make expand higher priority.)
imap <a-t> <Plug>(coc-snippets-expand-jump)

au FileType css,scss let b:prettier_exec_cmd = "prettier-stylelint"


