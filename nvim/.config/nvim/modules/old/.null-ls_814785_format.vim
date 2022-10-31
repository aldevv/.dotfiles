"====================
" NEOFORMAT
"====================
"
"this might be useful if null-ls fails in any regard
"
"
" let g:neoformat_verbose = 1
"
" let g:neoformat_run_all_formatters = 1
" Enable alignment globally
let g:neoformat_only_msg_on_error = 1
let g:neoformat_basic_format_align = 1
" Enable tab to spaces conversion globally
let g:neoformat_basic_format_retab = 1
" Enable trimmming of trailing whitespace globally
let g:neoformat_basic_format_trim = 1

" TODO turn on
" allows to search binary in node_modules
let g:neoformat_try_node_exe = 1
let g:neoformat_try_formatprg = 0
let g:neoformat_only_msg_on_error = 1
"vvvvvvvvvvvvvvvvv
augroup fmt
    autocmd!
    autocmd BufWritePre *.{js,java,cpp,haskell,json,ts,rs,go,html} :Neoformat
augroup END

function FormatSelector() abort
  " use coc-format for python
  let l:special_cases = ['py']
  if index(l:special_cases, g:extension) >= 0 " si esta en el arreglo
    nmap <silent><leader>cf <Plug>(coc-format)
  else
    nmap <silent><Leader>cf :Neoformat<cr>
  endif
endfunction
call FormatSelector()
" js,java,c,cpp,haskell,json,ts,rs,go
"-----------
" PYTHON
"-----------
" let g:neoformat_python_black = {
"             \ 'exe': 'black',
"             \ 'args': ['-','--quiet','--line-length', '100'],
"             \ 'stdin': 1,
"             \ }
" let g:neoformat_enabled_python = ['black', 'autopep8']

let g:neoformat_javascript_prettier = {
            \ 'exe': 'prettier',
            \ 'args': ['--stdin-filepath','"%:p"','--print-width','90', '--no-semi'],
            \ 'replace': 0,
            \ 'stdin': 1,
            \ 'try_node_exe': 1,
            \ }
let g:neoformat_enabled_javascript = ['prettier']


" \ 'args': ['-assume-filename=' . expand('%:t'), '-style=google'],
let g:neoformat_java_clangformat = {
            \ 'exe': 'clang-format',
            \ 'args': ['-assume-filename="' . expand('%:t').'"', '-style=file'],
            \ 'stdin': 1,
            \ }
let g:neoformat_enabled_java = ['clangformat']

let g:neoformat_cpp_clangformat = {
            \ 'exe': 'clang-format',
            \ 'args': ['-assume-filename="' . expand('%:t').'"', '-style=file'],
            \ 'stdin': 1,
            \ }
let g:neoformat_enabled_cpp = ['clangformat']

let g:neoformat_html_htmlbeautify = extend(neoformat#formatters#html#htmlbeautify(),{'try_node_exe': 1})
let g:neoformat_css_cssbeautify = extend(neoformat#formatters#css#cssbeautify(),{'try_node_exe': 1})

" let g:neoformat_html_htmlbeautify = {
            " \ 'exe': 'html-beautify',
            " \ 'stdin': 1,
            " \ 'try_node_exe': 1,
            "\ }

let g:neoformat_css_prettier = {
            \ 'exe': 'prettier',
            \ 'args': ['--stdin-filepath','"%:p"','--print-width','90', '--no-semi'],
            \ 'replace': 0,
            \ 'stdin': 1,
            \ 'try_node_exe': 1,
            \}
" neoformat#formatters#html#htmlbeautify() --> brings the config by default on neoformat
" if there is a default config, there is no need for let g:neoformat_filetype_formatter = {}
" if you wish to extend it, use extend(neoformat#formatters#html#htmlbeautify(),{'try_node_exe': 1})
" try_node_exe looks for binary in node_modules
let g:neoformat_enabled_html = ['prettier', 'htmlbeautify']
let g:neoformat_enabled_css = ['prettier', 'cssbeautify']


" lets you use gq
let s:formatprg_for_filetype = {
      \ "html"       : 'prettier --stdin-filepath ' . expand('%:p') . ' --print-width 90',
      \ "javascript" : 'prettier --stdin-filepath ' .expand('%'). ' --print-width 90',
      \ "css"        : 'prettier --stdin-filepath ' .expand('%'). ' --print-width 90',
      \ "c"          : 'clang-format --assume-filename=' . expand('%:t') . ' --style=file',
      \ "cpp"        : 'clang-format --assume-filename=' . expand('%:t'). ' --style=file',
      \ "cmake"      : "cmake-format --command-case lower -",
      \ "java"       : 'clang-format --assume-filename=' . expand('%:t'). ' --style=file',
      \ "go"         : "gofmt",
      \ "json"       : "js-beautify -s 2",
      \ "python"     : "autopep8 -",
      \ "sql"        : "sqlformat -k upper -r -",
      \}

for [ft, fp] in items(s:formatprg_for_filetype)
  execute "autocmd FileType ".ft." let &l:formatprg=\"".fp."\" | setlocal formatexpr="
endfor

" \ "css"        : "css-beautify -s 2 --space-around-combinator",
" \ "javascript" : "js-beautify -s 2",
" \ "c"          : "uncrustify --l C base kr mb",
" google style
" \ "c": 'clang-format --assume-filename=' . expand('%:t'). ' -style=google'
" \ "cpp"        : "uncrustify --l CPP base kr mb stroustrup",
"\ "java"       : "uncrustify --l JAVA base kr mb java",
