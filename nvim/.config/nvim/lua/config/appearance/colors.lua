-- cmp
-- do nvim --headless to see errors, guifg was MISSING
vim.cmd([[
    augroup cmp
        execute 'hi! CmpItemAbbr guifg=LightGreen'
        "execute 'hi! CmpItemAbbrMatch guifg=Pink'
        "execute 'hi! CmpItemAbbrMatch guifg='. HighGet("String")
    augroup END
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
