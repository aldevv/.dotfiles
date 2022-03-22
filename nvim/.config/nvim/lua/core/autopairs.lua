-- AUTOPAIRS-nvim
-- require('nvim-autopairs').setup{
-- disable_filetype = { "TelescopePrompt" },
-- disable_in_macro = true,  -- disable when recording or executing a macro
-- disable_in_visualblock = false, -- disable when insert after visual block mode
-- ignored_next_char = string.gsub([[ [%w%%%'%[%"%.] ]],"%s+", ""),
-- enable_moveright = true,
-- enable_afterquote = true,  -- add bracket pairs after quote
-- enable_check_bracket_line = true,  --- check bracket in same line
-- check_ts = false,
-- map_bs = true,  -- map the <BS> key
-- map_c_h = false,  -- Map the <C-h> key to delete a pair
-- map_c_w = false, -- map <c-w> to delete a pair if possible
-- fast_wrap = {
--       map = '<M-a>',
--       chars = { '{', '[', '(', '"', "'" },
--       pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], '%s+', ''),
--       offset = -1, -- Offset from pattern match
--       end_key = '$',
--       keys = 'qwertyuiopzxcvbnmasdfghjkl',
--       check_comma = true,
--       highlight = 'Search',
--       highlight_grey='Error'
--     },
-- }




-- "==========
-- " AUTO-PAIRS --old one
-- "==========
-- " System Shortcuts:
-- "     <CR> : Insert new indented line after return if cursor in blank brackets
-- "            or quotes.
-- "     <BS> : Delete brackets in pair
-- "     <M-p>: Toggle Autopairs (|g:AutoPairsShortcutToggle|)
-- "     <M-n>: Jump to next closed pair (|g:AutoPairsShortcutJump|)
-- "     <M-b>: BackInsert { (|g:AutoPairsShortcutBackInsert|) }
-- "     <M-e>: 'Fast' 'Wrap' (g:AutoPairsShortcutFastWrap)
-- "     { n n{ e n
-- "     << ()

-- " testing
vim.g.AutoPairsFlyMode = 0
vim.g.AutoPairsMultilineClose = 0
vim.g.AutoPairsMapBS=1
vim.g.AutoPairsMapCh = 0 --use pars mapBS better"

vim.g.AutoPairsSingleQuoteExpandFor = "fbr" --they are not gonna mess much in english for f''
vim.g.AutoPairsDoubleQuoteExpandFor = 'fbr'
vim.g.AutoPairsSingleQuoteMode = 2
vim.g.AutoPairsDoubleQuoteMode = 2
vim.g.AutoPairsShortcutFastWrap = '<a-a>'
vim.g.AutoPairsShortcutJump = '<a-w>'
vim.g.AutoPairsShortcutToggle = ''
vim.g.AutoPairsShortcutBackInsert = '<a-b>' -- only for flymode
vim.g.autopairs_enable=1
