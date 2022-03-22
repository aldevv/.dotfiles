"===================
" VIMSPECTOR
"===================
" let g:vimspector_enable_mappings = 'HUMAN'
" packadd! vimspector
" nmap <leader>dw :VimspectorWatch
" autocmd Filetype java nmap <leader>dd :CocCommand java.debug.vimspector.start<cr>
"enable python debugging
" :VimspectorInstall vscode-python
"
fun GotoWindow(id)
    call win_gotoid(a:id)
    MaximizerToggle
endfun
let g:vimspector_install_gadgets = [ 'debugpy', 'CodeLLDB' ]
" setup guide for java https://urfoex.blogspot.com/2020/08/debugging-java-with-jdb-or-vim.html

nnoremap <leader><leader>dc :call GotoWindow(g:vimspector_session_windows.code)<cr>
nnoremap <leader><leader>dt :call GotoWindow(g:vimspector_session_windows.tagpage)<cr>
nnoremap <leader><leader>dv :call GotoWindow(g:vimspector_session_windows.variables)<cr>
nnoremap <leader><leader>dw :call GotoWindow(g:vimspector_session_windows.watches)<cr>
nnoremap <leader><leader>ds :call GotoWindow(g:vimspector_session_windows.stack_trace)<cr>
nnoremap <leader><leader>do :call GotoWindow(g:vimspector_session_windows.stack_output)<cr>

nnoremap <leader><leader>dd :call vimspector#Launch()<CR>
nnoremap <silent> <leader><leader>di :silent exec '!createdbg ' . shellescape(g:extension) . ' ' . shellescape(expand("%:r"))<cr>
nmap <leader><leader>dD  <Plug>VimspectorStop
nnoremap <leader><leader>dr :call vimspector#Reset()<cr>
nmap <leader><leader>dR <Plug>VimspectorRestart
nmap <leader><leader>dl <Plug>VimspectorStepInto
nmap <leader><leader>dn <Plug>VimspectorStepOver
nmap <leader><leader>de <Plug>VimspectorStepOut
nmap <leader><leader>dp <Plug>VimspectorPause
nnoremap <leader><leader>d<space> :call vimspector#Continue()<cr>
nmap <leader><leader>dC <Plug>VimspectorRunToCursor
nmap <leader><leader>db <Plug>VimspectorToggleBreakpoint
nmap <leader><leader>dB <Plug>VimspectorToggleConditionalBreakpoint
 " <Plug>VimspectorAddFunctionBreakpoint

" default config for a javascript file!
" Javascript
"{
"  "configurations": {
"    "run": {
"      "adapter": "vscode-node",
"      "configuration": {
"        "request": "launch",
"        "protocol": "auto",
"        "stopOnEntry": true,
"        "console": "integratedTerminal",
"        "program": "${workspaceRoot}/nice.js",
"        "cwd": "${workspaceRoot}"
"      }
"    },
"    "foobar": {}
"  }
"}


