vim.cmd([[
"===================
"for transparent vim
"===================
highlight clear SignColumn
set cursorline
set cursorcolumn
" use this to FOLLOW links in highlight groups (can make persistent in
" colorscheme changes)
function! g:HighGet(name)
    return 'guifg=' . synIDattr(synIDtrans(hlID(a:name)), "fg")
endfunction
function! s:HighGetEcho(name)
    echo 'guifg=' . synIDattr(synIDtrans(hlID(a:name)), "fg")
endfunction
command! -nargs=1 Hg call s:HighGetEcho(<f-args>)

"python gruvbox
function MyPythonHighlights()
    execute 'hi! pythonClassVar gui=italic '    . HighGet("pythonClassVar")
    execute 'hi! pythonImport   gui=italic '    . HighGet("pythonImport")
    execute 'hi! pythonBuiltinFunc gui=italic ' . HighGet("pythonBuiltinFunc")
    execute 'hi! pythonClass gui=italic '       . HighGet("Statement")
    match pythonClass /^class\s/
    " created python class highlight group
endfunction

function MyMarkdownHighlights()
    execute 'hi! htmlItalic gui=italic ' . HighGet("htmlItalic")
endfunction

" to create a highlight group
" hi! pythonClass   gui=italic ctermfg=109 guifg=#83a598
" match pythonClass /^class\s/

" Js colors
" ________________
" find the highlight group using SyntaxQuery (on top of the desired item)
" then use :hi <name> to find the details of that item, do it as many times
" you need until you find the root colors
"
function MyJsHighlights()
    execute 'hi! jsImport         gui=italic ' . HighGet("jsImport")
    execute 'hi! jsFrom           gui=italic ' . HighGet("jsFrom")
    execute 'hi! jsClassKeyword   gui=italic ' . HighGet("jsClassKeyword")
    execute 'hi! jsExtendsKeyword gui=italic ' . HighGet("jsExtendsKeyword")
endfunction

function MyJavaHighlights()
    execute 'hi! javaIdentifier  guifg=#F5F5F5'
    execute 'hi! javaType         gui=italic ' . HighGet("javaType")
endfunction

 execute 'hi! lineNr guibg=NONE ' . HighGet("lineNr")


let g:java_highlight_all = 1
" to see the type of highlight SyntaxQuery
function! s:syntax_query() abort
  for id in synstack(line("."), col("."))
    echo synIDattr(id, "name")
  endfor
endfunction
command! SyntaxQuery call s:syntax_query()

" use custom highlights (italics)
if empty(getenv('NOCOC'))
let custom_highlights = 1

if custom_highlights == 1
    "commented because there's an error
    " autocmd FileType python call MyPythonHighlights()
    " autocmd FileType javascript call MyJsHighlights()
    " autocmd FileType java call MyJavaHighlights()
    " autocmd FileType markdown call MyMarkdownHighlights()
endif
endif

function FoldText()
	let line = getline(v:foldstart)
	let numOfLines = v:foldend - v:foldstart
	let fillCount = winwidth('%') - len(line) - len(numOfLines) - 14
	return line . ' [' . numOfLines . ' lines]' . repeat('.', fillCount)
endfunction
set foldtext=FoldText()
set fillchars=fold:\  " removes trailing dots. Mind that there is a whitespace after the \!
]])
