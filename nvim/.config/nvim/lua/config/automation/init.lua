local cmd = vim.cmd
require("config.automation.filetypes")

cmd([[
" Remove trailing whitespace on save
let ext = expand('%:e')
if ext == "vim" || ext == "lua"
   autocmd BufWritePre * %s/\s\+$//e
endif
" auto compile status bar dwm
    autocmd BufWritePost dwmstatus :!killall dwmstatus; setsid dwmstatus &

" auto compile suckless programs MODIFY TO GET BORDER
    " autocmd BufWritePost config.h !cd $(compileSuckless %); sudo make clean install
    autocmd BufWritePost config.h :call CompileSuck()

    function CompileSuck()
        let _path = expand('%:p:h')
        let name = system('basename '.shellescape(_path))
        if name =~ "dwm"
            echo name
            :exec '!changeWallpaperKeepBorders'
        else
            :exec 'cd '. name
            :exec '!sudo make clean install'
        endif
    endfunction
" auto compile latex if no vimtex
    autocmd BufWritePost,CursorHold,CursorHoldI *.tex :silent call CompileTex()

" auto compile xresources
    autocmd BufWritePost *.Xresources !xrdb -merge ~/.Xresources

" auto compile sxhkd
    autocmd BufWritePost *sxhkdrc :!killall -s SIGUSR1 sxhkd

" auto shortcuts
  autocmd BufWritePost,TextChanged sf,sd !$AUTOMATION/shortcuts

augroup highlight_yank
   autocmd!
   autocmd TextYankPost * silent! lua require'vim.highlight'.on_yank()
augroup END

autocmd! BufRead,BufNewFile .projections.json  set filetype=projections.json syntax=json
]])


local patterns = "*.{js,jsx,java,c,cpp,hs,json,ts,tsx,rs,go,html,svelte,vue,py,hs,sh,lua}"
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = patterns,
  callback = function()
    vim.lsp.buf.format()
  end,
})

-- require("config.automation.packer")

-- require("config.automation.lsp").diagnostics_in_loclist() --

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

-- NOTE: source file after save if is lua
-- cmd([[
--     autocmd BufWritePost *.lua :luafile %
-- ]])

cmd([[
     autocmd FileType org,markdown,javascript,javascriptreact,typescript,typescriptreact,svelte,vue :set shiftwidth=2 tabstop=2 softtabstop=2
]])

-- cmd([[
--      autocmd BufReadPre *.http :set filetype=http
-- ]])

vim.api.nvim_create_autocmd({ "Filetype" }, {
  pattern = "*",
  callback = function()
    vim.opt.cursorline = true
    vim.api.nvim_set_hl(0, "HarpoonWindow", { link = "Normal" })
    vim.api.nvim_set_hl(0, "HarpoonBorder", { link = "Normal" })
    vim.api.nvim_set_hl(0, "FloatWindow", { link = "Normal" })
    vim.api.nvim_set_hl(0, "FloatBorder", { link = "Normal" })
  end,
})

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  pattern = vim.fn.getenv("NOTES") .. "/*.md",
  command = "Dispatch! . _dgp $NOTES $(stamp)",
})

-- NOTE: this is because the file appears with wrong highlighting, fault of the lsp
vim.api.nvim_create_autocmd({ "LspAttach" }, {
  pattern = "*/dwm-flexipatch/config.h",
  command = "LspStop",
})

vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "TelescopePrompt*", "TelescopeResults" },
  command = "setlocal nocursorline",
})

vim.api.nvim_create_autocmd({ "TermOpen" }, {
  pattern = "*",
  callback = function()
    -- pcall(vim.cmd, "set background=dark")
    -- pcall(vim.cmd, "hi Normal guibg=NONE ctermbg=NONE")
    pcall(vim.cmd, "setlocal nospell")
  end,
})
