local M = {}
M.ufo_mappings = function()
  vim.keymap.set("n", "zR", require("ufo").openAllFolds)
  vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
  vim.keymap.set("n", "zr", require("ufo").openFoldsExceptKinds)
  vim.keymap.set("n", "zm", require("ufo").closeFoldsWith) -- closeAllFolds == closeFoldsWith(0)
  vim.keymap.set("n", "+", function()
    local winid = require("ufo").peekFoldedLinesUnderCursor()
    if not winid then
      vim.lsp.buf.hover()
    end
  end)
end

M.load_mappings = function(client) -- use these on_attach
  local s = { silent = true }
  local nor = { noremap = true }
  local nor_s = vim.tbl_extend("keep", nor, s)
  local map = vim.keymap.set
  -- lsp
  -- https://rishabhrd.github.io/jekyll/update/2020/09/19/nvim_lsp_config.html

  -- prefix , --> config
  map("n", "<leader>lf", ":lua vim.lsp.buf.format({async = true})<cr>", nor)
  -- needs to be this way for it to work (stays in visual mode, no enter)
  map("v", "<leader>lf", vim.lsp.buf.format, nor)
  map("v", "gq", vim.lsp.buf.format, nor)

  -- map("n", "gd", ":lua vim.lsp.buf.definition()<cr>", nor)
  -- NOTE: ge can be remapped
  --       gE can be remmaped
  --       <leader>f can be remmaped
  --       <leader>e can be remmaped

  map("n", "gd", ":Telescope lsp_definitions<cr>", nor_s)
  map("n", "gD", ":vsplit | lua vim.lsp.buf.definition()<cr>")
  map("n", "gS", ":split | lua vim.lsp.buf.definition()<cr>")
  map("n", "gr", ":Telescope lsp_references<cr>", nor)
  map("n", "gR", ":lua vim.lsp.buf.references()<cr>", nor)
  map("n", "gy", ":lua vim.lsp.buf.type_definition()<cr>", nor)
  map("n", "gY", ":lua vim.lsp.buf.declaration()<cr>", nor)
  M.ufo_mappings() --includes hover
  map("n", "<M-->", vim.lsp.buf.signature_help, nor)
  map("i", "<a-->", "<C-\\><C-O>:lua require('lsp_signature').signature()<cr>", nor)
  -- map("n", "+", "<cmd>Lspsaga hover_doc<cr>", nor)

  -- map("i", "<a-->", "<C-\\><C-O>:lua vim.lsp.buf.signature_help()<cr>", nor)
  map("n", "<c-space>", ":lua vim.lsp.buf.completion()<cr>", nor)
  map("n", "<leader>ls", ":Telescope lsp_document_symbols<cr>", nor)
  map("n", "<leader>lS", ":Telescope lsp_workspace_symbols<cr>", nor)

  -- map("n", "<leader>lS", ":lua vim.lsp.buf.document_symbol()<cr>", nor)
  map("n", "<leader>la", ":lua vim.lsp.buf.code_action()<cr>", nor)
  map("v", "<leader>la", ":lua vim.lsp.buf.code_action()<cr>", nor)

  map("n", "<leader>lh", ":lua vim.lsp.buf.document_highlight()<cr>", nor) -- for highlighting text
  -- map("n", "<leader>lL", ":lua vim.lsp.buf.clear_references()<cr>", nor)
  map("n", "<leader>lr", ":lua vim.lsp.buf.rename()<cr>", nor)
  map("n", "<F2>", ":lua vim.lsp.buf.rename()<cr>", nor)

  map("n", "gi", ":Telescope lsp_implementations<cr>", nor)
  -- map("n", "<leader>li", ":lua vim.lsp.buf.implementation()<cr>", nor)

  map("n", "<leader>lci", ":lua vim.lsp.buf.incoming_calls()<cr>", nor)
  map("n", "<leader>lco", ":lua vim.lsp.buf.outgoing_calls()<cr>", nor)

  vim.cmd([[ cnoreabbrev LspCmd :lua vim.lsp.buf.execute_command() ]])

  -- codelens
  map("n", "<leader>ecd", ":lua vim.lsp.codelens.display()<cr>", nor)
  -- map("n", "<leader>lcd", ":lua vim.lsp.codelens.display()<cr>", nor)
  map("n", "<leader>lcR", ":lua vim.lsp.codelens.refresh()<cr>", nor)
  map("n", "<leader>lcr", ":lua vim.lsp.codelens.run()<cr>", nor)

  -- prefix w --> workspace
  map("n", "<leader>lws", ":Telescope lsp_workspace_symbols<cr>", nor)
  map("n", "<leader>lwf", ":lua vim.lsp.buf.add_workspace_folder()<cr>", nor)
  map("n", "<leader>lwl", ":lua vim.lsp.buf.list_workspace_folders()<cr>", nor)
  map("n", "<leader>lwr", ":lua vim.lsp.buf.remove_workspace_folder()<cr>", nor)

  -- prefix o --> diagnostics

  map("n", "go", ":lua vim.diagnostic.open_float()<cr>", nor)

  -- lsp saga truncating output agressively (showing only part of diagnostic) as of 23/11/22
  -- https://github.com/glepnir/lspsaga.nvim/issues/527
  -- map("n", "go", "<cmd>Lspsaga show_line_diagnostics<cr>", nor)

  map("n", "<leader>ldD", "<cmd>Lspsaga lsp_finder<cr>", nor)
  map("n", "<leader>oo", ":lua  require('telescope.builtin').diagnostics({bufnr=0})<cr>", nor)
  map("n", "<leader>oO", ":lua  require('telescope.builtin').diagnostics()<cr>", nor)
  map("n", "<leader>owo", ":lua  require('telescope.builtin').diagnostics()<cr>", nor)
  vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
  vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
  map("n", "<leader>ok", "<cmd>Lspsaga diagnostic_jump_next<cr>", nor)
  map("n", "<leader>oK", "<cmd>Lspsaga diagnostic_jump_prev<cr>", nor)
  map("n", "<leader>on", ":lua vim.diagnostic.get_namespace()<cr>", nor)
  map("n", "<leader>ol", ":lua vim.diagnostic.setloclist{ title = 'Buffer diagnostics' }<cr>", nor)
  map("n", "<leader>oq", ":lua vim.diagnostic.setqflist{ title = 'Workspace diagnostics' }<cr>", nor)
  -- map("n", "<leader>ok", ":lua vim.diagnostic.goto_next()<cr>", nor)
  -- map("n", "<leader>oK", ":lua vim.diagnostic.goto_prev()<cr>", nor)
  require("config.keybindings.langs")[client]()
end

return M
