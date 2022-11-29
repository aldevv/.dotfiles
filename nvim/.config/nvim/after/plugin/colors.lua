-- put hover signature_help and cmp help transparent

vim.cmd([[
    hi clear SpellBad
    hi link SpellBad GruvboxRed
]])

-- transparency
vim.cmd("hi Normal guibg=NONE ctermbg=NONE")
