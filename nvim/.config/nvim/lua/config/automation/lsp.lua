local M = {}

M.diagnostics_in_loclist = function()
    vim.cmd([[
	    autocmd DiagnosticChanged * lua vim.diagnostic.setloclist({open = false })
    ]])
end
return M
