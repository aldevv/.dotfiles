local cmd = vim.cmd
require("config.automation.filetypes")
cmd([[
  augroup FormatOnSave
    autocmd!
    " so when it saves it stays saved
     autocmd BufWritePre *.{js,jsx,java,c,cpp,hs,json,ts,tsx,rs,go,html,svelte,vue,py,hs,sh,lua} :lua vim.lsp.buf.format()
    " uncomment when you change to neovim 0.8
    " autocmd BufWritePre *.{js,jsx,java,c,cpp,hs,json,ts,tsx,rs,go,html,svelte,vue,py,hs,sh,lua} :lua vim.lsp.buf.formatting_sync()
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

if is_work_env() then
    vim.opt.spelllang = "en_us"
else
    vim.opt.spelllang = "en_us,es"
end

-- since spelling commented options is a pain
-- disable if you ever need to build something using lua
cmd([[
    augroup MardownAuto
            autocmd BufReadPre *.{lua} :set nospell
    augroup END
]])

cmd([[
autocmd FileType org nnoremap <leader>ll :VimtexCompile<cr>
]])
