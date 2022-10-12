local cmd = vim.cmd
require("config.automation.filetypes")
cmd([[
  augroup FormatOnSave
    autocmd!
    " so when it saves it stays saved
     autocmd BufWritePre *.{js,java,c,cpp,hs,json,ts,rs,go,html,svelte,vue,py,hs,sh,lua} :lua vim.lsp.buf.format()
    " uncomment when you change to neovim 0.8
    " autocmd BufWritePre *.{js,java,c,cpp,hs,json,ts,rs,go,html,svelte,vue,py,hs,sh,lua} :lua vim.lsp.buf.formatting_sync()
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
