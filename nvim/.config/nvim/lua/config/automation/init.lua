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

" auto compile xresources
    autocmd BufWritePost *.Xresources !xrdb -merge ~/.Xresources

" auto compile sxhkd
    autocmd BufWritePost *sxhkdrc :!killall -s SIGUSR1 sxhkd

" auto shortcuts
  autocmd BufWritePost,TextChanged sf,sd !$AUTOMATION/shortcuts

augroup highlight_yank
   autocmd!
   autocmd TextYankPost * silent! lua require'vim.highlight'.on_yank({higroup="IncSearch", timeout=40})
augroup END

autocmd! BufRead,BufNewFile .projections.json  set filetype=projections.json syntax=json

function! ExecuteMacroOverVisualRange()
  echo "@".getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction
]])
vim.keymap.set("x", "@", ":<C-u>call ExecuteMacroOverVisualRange()<cr>")


local patterns = "*.{js,jsx,java,c,cpp,hs,json,ts,tsx,rs,go,html,svelte,vue,py,hs,sh,lua}"
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = patterns,
  callback = function()
    vim.lsp.buf.format()
  end,
})

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

local notes_path = os.getenv("NOTES") or ""
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  pattern = notes_path .. "/*.md",
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
  command = "setlocal nospell"
})
