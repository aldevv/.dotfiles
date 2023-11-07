-- cmp
-- do nvim --headless to see errors, guifg was MISSING
vim.cmd([[
    augroup cmp
        execute 'hi! CmpItemAbbr guifg=LightGreen'
        "execute 'hi! CmpItemAbbrMatch guifg=Pink'
        "execute 'hi! CmpItemAbbrMatch guifg='. HighGet("String")
    augroup END
]])

-- tab and eol colors
vim.cmd([[
  execute 'hi WhiteSpace guifg=gray'
  execute 'hi NonText guifg=gray'
]])

-- hop
--
vim.cmd([[
    execute 'hi HopNextKey2 gui=bold guifg=LightGreen'
]])

vim.cmd([[
let g:brightest#highlight = {
            \   "group" : "WildMenu"
            \}

let g:brightest#highlight_in_cursorline = {
            \ "group": "Wildmenu"
            \}

let g:brightest#pattern = '\k\+'

let g:brightest#enable_filetypes = {
            \ "_": 1
            \}
]])

--fugitive diff
-- vim.cmd([[
-- hi diffAdded ctermfg=188 ctermbg=64 cterm=bold guifg=#50FA7B guibg=NONE gui=bold
-- hi diffRemoved ctermfg=88 ctermbg=NONE cterm=NONE guifg=#FA5057 guibg=NONE gui=NONE
-- ]])
