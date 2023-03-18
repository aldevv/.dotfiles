local M = {}

M.diagnostics_in_loclist = function()
    vim.cmd([[
	    autocmd DiagnosticChanged * lua vim.diagnostic.setloclist({open = false })
	    " autocmd DiagnosticChanged * lua vim.fn.setloclist(0,vim.diagnostic.get())
    ]])
end
return M
