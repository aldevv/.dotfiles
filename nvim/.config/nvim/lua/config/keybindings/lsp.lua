local M = {}
M.load_mappings = function() -- use these on_attach
    local s = { silent = true }
    local nor = { noremap = true }
    local nor_s = vim.tbl_extend("keep", nor, s)
    local map = vim.api.nvim_set_keymap
    -- lsp
    -- https://rishabhrd.github.io/jekyll/update/2020/09/19/nvim_lsp_config.html

    -- prefix , --> config

    -- prefix l --> lsp --> TODO change to e or i
    map("n", "<leader>lf", ":lua vim.lsp.buf.formatting()<cr>", nor)
    map("v", "<leader>lf", ":lua vim.lsp.buf.range_formatting()<cr>", nor)

    map("n", "gd", ":lua vim.lsp.buf.definition()<cr>", nor)
    map("n", "gr", ":lua vim.lsp.buf.references()<cr>", nor)
    map("n", "+", ":lua vim.lsp.buf.hover()<cr>", nor)

    map("n", "<M-->", ":lua vim.lsp.buf.signature_help()<cr>", nor)
    map("i", "<a-->", "<C-\\><C-O>:lua vim.lsp.buf.signature_help()<cr>", nor)
    map("n", "<c-space>", ":lua vim.lsp.buf.completion()<cr>", nor)
    map("n", "<leader>ls", ":lua vim.lsp.buf.document_symbol()<cr>", nor)
    map("n", "<leader>ldd", ":lua vim.lsp.buf.declaration()<cr>", nor)
    map("n", "<leader>ldl", ":lua vim.diagnostic.setloclist{ title = 'Buffer diagnostics' }<cr>", nor)
    map("n", "<leader>ldq", ":lua vim.diagnostic.setqflist{ title = 'Workspace diagnostics' }<cr>", nor)
    map("n", "<leader>lt", ":lua vim.lsp.buf.type_definition()<cr>", nor)
    map("n", "<leader>la", ":lua vim.lsp.buf.code_action()<cr>", nor)
    map("v", "<leader>la", ":lua vim.lsp.buf.range_code_action()<cr>", nor)

    map("n", "<leader>lh", ":lua vim.lsp.buf.document_highlight()<cr>", nor) -- for highlighting text
    map("n", "<leader>ll", ":lua vim.lsp.buf.clear_references()<cr>", nor)
    -- autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()
    -- autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()
    -- autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()

    map("n", "<leader>ii", ":lua vim.lsp.buf.implementation()<cr>", nor)
    -- map("n", "<leader>li", ":lua vim.lsp.buf.implementation()<cr>", nor)

    map("n", "<leader>ci", ":lua vim.lsp.buf.incoming_calls()<cr>", nor)
    map("n", "<leader>co", ":lua vim.lsp.buf.outgoing_calls()<cr>", nor)
    map("n", "<leader>lr", ":lua vim.lsp.buf.rename()<cr>", nor)

    vim.cmd([[ cnoreabbrev LspCmd :lua vim.lsp.buf.execute_command() ]])

   -- codelens
    map("n", "<leader>ecd", ":lua vim.lsp.codelens.display()<cr>", nor)
    -- map("n", "<leader>lcd", ":lua vim.lsp.codelens.display()<cr>", nor)
    map("n", "<leader>lcR", ":lua vim.lsp.codelens.refresh()<cr>", nor)
    map("n", "<leader>lcr", ":lua vim.lsp.codelens.run()<cr>", nor)

    -- prefix w --> workspace
    map("n", "<leader>lws", ":lua vim.lsp.buf.workspace_symbol()<cr>", nor)
    map("n", "<leader>lwf", ":lua vim.lsp.buf.add_workspace_folder()<cr>", nor)
    map("n", "<leader>lwl", ":lua vim.lsp.buf.list_workspace_folders()<cr>", nor)
    map("n", "<leader>lwr", ":lua vim.lsp.buf.remove_workspace_folder()<cr>", nor)

    -- prefix o --> diagnostics
    map("n", "<leader>oo", ":lua vim.diagnostic.open_float()<cr>", nor)
    map("n", "<leader>ok", ":lua vim.diagnostic.goto_next()<cr>", nor)
    map("n", "<leader>oK", ":lua vim.diagnostic.goto_prev()<cr>", nor)
    map("n", "<leader>on", ":lua vim.lsp.diagnostic.get_namespace()<cr>", nor)
    map("n", "<leader>ol", ":lua vim.diagnostic.setloclist()<cr>", nor)
    map("n", "<leader>oq", ":lua vim.diagnostic.setqflist()<cr>", nor)
end

return M
