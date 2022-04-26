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
        let path = expand('%:p:h')
        let name = system('basename '.shellescape(path))
        " exec 'echo '.shellescape(name)
        silent exec '!cd ' . shellescape(path)
        if name =~ "dwm-6.2"
            echo name
            :exec '!changeWallpaperKeepBorders'
        else
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
    autocmd BufWritePost,TextChanged sf,sd !$AUTOMATION/shortcut_maker_better

" functions
function Autosaving()
    autocmd TextChanged,TextChangedI <buffer> silent! write
endfunction

augroup highlight_yank
   autocmd!
   autocmd TextYankPost * silent! lua require'vim.highlight'.on_yank()
augroup END

autocmd! BufRead,BufNewFile .projections.json  set filetype=projections.json syntax=json
autocmd! BufRead,BufNewFile .vimspector.json  set filetype=vimspector.json syntax=json

" for tmux
autocmd BufReadPost,FileReadPost,BufNewFile * call system("tmux rename-window " . expand("%:t:r"))
