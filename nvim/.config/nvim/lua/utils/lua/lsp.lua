local M = {}

M.update_diagnostics = function(opts)
    local global_too = opts.global_too
    -- vim.lsp.buf.server_ready() was removed in nvim 0.11.
    -- Use the client list as the readiness signal.
    if #vim.lsp.get_clients({ bufnr = 0 }) == 0 then
        return
    end
    if vim.fn.getloclist(vim.fn.winnr(), { title = 0 }).title == "Buffer diagnostics" then
        vim.diagnostic.setloclist { open = false, title = "Buffer diagnostics" }
    end
    if global_too and vim.fn.getqflist({ title = 0 }).title == "Workspace diagnostics" then
        vim.diagnostic.setqflist { open = false, title = "Workspace diagnostics" }
    end
end

return M
