-- "============
-- " CLOSE TAGS
-- "============
-- "
-- " filetypes like xml, html, xhtml, ...
-- " These are the file types where this plugin is enabled.
-- "
vim.g.closetag_filetypes = 'html,xhtml,phtml,js,jsx,ts,tsx,xml'

-- " filetypes like xml, xhtml, ...
-- " This will make the list of non-closing tags self-closing in the specified files.
-- "
vim.g.closetag_xhtml_filetypes = 'xhtml,jsx,ts,js,html,xml'

-- " integer value [0|1]
-- " This will make the list of non-closing tags case-sensitive (e.g. `<Link>` will be closed while `<link>` won't.)
-- "
vim.g.closetag_emptyTags_caseSensitive = 1

-- " dict
-- " Disables auto-close if not in a "valid" region (based on filetype)
-- "
vim.cmd([[
let g:closetag_regions = {'typescript.tsx': 'jsxRegion,tsxRegion','javascript.jsx': 'jsxRegion' }
]])
-- " Shortcut for closing tags, default is '>'
vim.g.closetag_shortcut = '>'
-- " Add > at current position without closing the current tag, default is ''
-- "this is for adding a single > with no pair, bug with space
vim.g.closetag_close_shortcut = '<leader>>'
