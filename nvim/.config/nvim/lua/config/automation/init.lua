local cmd = vim.cmd
cmd([[
  augroup FormatOnSave
    autocmd!
    " so when it saves it stays saved
    autocmd BufWritePre *.{js,java,cpp,hs,json,ts,rs,go,html,svelte,vue,py,hs,sh,lua} :lua vim.lsp.buf.formatting_sync()
  augroup END
]])

cmd([[
    augroup ReloadNvimConfig
        autocmd BufWritePost *.{lua,vim} source %
    augroup END
]])

require("config.automation.packer")

require("config.automation.lsp").diagnostics_in_loclist() --

-- so far is working
-- cmd('autocmd BufReadPre *.{html,css,js,jsx,ts} EmmetInstall')

-- cmd('autocmd Filetype tex let b:AutoPairs = {"(": ")", "[": "]"}')
cmd(
    "autocmd VimEnter,WinEnter,BufNewFile,BufRead,BufEnter,TabEnter *.{vim,jsx,json,ts,js,svelte,vue} :IndentLinesToggle"
)

cmd([[
    function! NetrwMaps()
        :nnoremap ? :help netrw-quickmap<CR>
        nmap <buffer> P <C-w>z
        "open file and close netrw
        nmap <buffer> L <CR>:Lexplore<CR>
    endfunction

    augroup NetrwSettings
        autocmd!
        autocmd FileType netrw execute 'call NetrwMaps()'
    augroup END
]])

--autopairs disabled
-- cmd("autocmd FileType TelescopePrompt let b:autopairs_enabled = 0")

cmd([[
function! ExecuteMacroOverVisualRange()
  echo "@".getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction
]])

-- cmd([[
--     augroup Wiki
--         autocmd!
--         autocmd BufWritePost  *.org :!rclone sync $WIKI gd:wiki
--     augroup END
--     ]])
