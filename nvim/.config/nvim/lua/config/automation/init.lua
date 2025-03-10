local cmd = vim.cmd
require("config.automation.filetypes")

cmd([[
    function CompileSuck()
        let _path = expand('%:p:h')
        let name = system('basename '.shellescape(_path))
        if name =~ "dwm"
            echo name
            :exec '!changeWallpaperKeepBorders'
        else
            :exec 'cd '. _path
            :exec '!sudo make PREFIX=$HOME/.local/builds/st clean install '
        endif
    endfunction
]])
-- :exec '!sudo make clean install '

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  pattern = "config.h",
  command = "call CompileSuck()",
})

-- " auto compile status bar dwm
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  pattern = "dwmstatus",
  command = "!killall dwmstatus; setsid dwmstatus &",
})

vim.cmd([[
  " Remove trailing whitespace on save
  let ext = expand('%:e')
  if ext == "vim" || ext == "lua"
     autocmd BufWritePre * %s/\s\+$//e
  endif
]])

vim.cmd([[
  augroup highlight_yank
     autocmd!
     autocmd TextYankPost * silent! lua require'vim.highlight'.on_yank({higroup="IncSearch", timeout=40})
  augroup END
]])

vim.cmd([[
  function! ExecuteMacroOverVisualRange()
    echo "@".getcmdline()
    execute ":'<,'>normal @".nr2char(getchar())
  endfunction
]])
vim.keymap.set("x", "@", ":<C-u>call ExecuteMacroOverVisualRange()<cr>")

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = ".projections.json",
  command = "set filetype=projections.json syntax=json",
})

-- " auto shortcuts
vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged" }, {
  pattern = "sf,sd",
  command = "!$AUTOMATION/shortcuts",
})

-- " auto compile xresources
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  pattern = "*.Xresources",
  command = "!xrdb -merge ~/.Xresources",
})
-- " auto compile sxhkd
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  pattern = "*sxhkdrc",
  command = "!killall -s SIGUSR1 sxhkd",
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
  command = "setlocal nospell",
})

vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "javascriptreact", "typescriptreact" },
  command = "setlocal nospell",
})

vim.api.nvim_create_autocmd({ "BufRead" }, {
  pattern = ".envrc",
  command = "set ft=bash",
})

vim.api.nvim_create_autocmd({ "BufRead" }, {
  pattern = "*.keymap",
  callback = function()
    vim.bo.syntax = "dts"
    vim.opt.formatoptions:remove({ "r", "o", "t" })
  end,
})

vim.api.nvim_create_autocmd({ "BufEnter" }, {
  pattern = "*",
  callback = function()
    vim.opt.formatoptions:remove({ "r", "o", "t" })
  end,
})


-- slows down saving
local patterns = "*.{js,jsx,mjs,java,c,cpp,hs,json,ts,tsx,rs,go,html,svelte,vue,py,hs,sh,lua,tf,tfvars}"
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = patterns,
  callback = function()
    vim.lsp.buf.format()
  end,
})


vim.api.nvim_create_autocmd({ "BufEnter" }, {
  pattern = "*.py",
  callback = function()
    -- to show self in a different color than white
    -- you can check it with :Inspect
    vim.api.nvim_set_hl(0, '@lsp.type.parameter.python', {})
  end,
})
