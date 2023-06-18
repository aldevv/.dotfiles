local s = { silent = true }
local nor = { noremap = true }
local e = { expr = true }
local b = { buffer = true }
local s_e = vim.tbl_extend("keep", s, e)
local nb = vim.tbl_extend("keep", nor, b)

local nor_s = vim.tbl_extend("keep", nor, s)
local nor_e = vim.tbl_extend("keep", nor, e)
local nor_e_s = vim.tbl_extend("keep", nor, e, s)

local map = vim.keymap.set

local desc = function(desc)
  return vim.tbl_extend("keep", nor_s, { desc = desc })
end

local descv = function(desc)
  return vim.tbl_extend("keep", nor, { desc = desc })
end

local descb = function(desc)
  return vim.tbl_extend("keep", nor, { desc = desc, buffer = true })
end

local M = {}
M.gopls = function()
  map("n", "Esj", "<cmd>GoTag json <CR>", { desc = "Add json struct tags" })
  map("n", "Esb", "<cmd>GoTag bson <CR>", { desc = "Add bson struct tags" })
  map("n", "Est", "<cmd>GoTag json,omitempty", { desc = "Add json custom struct tags" })
  map("n", "Esrj", "<cmd>GoTag json --rm <CR>", { desc = "Rm json struct tags" })
  map("n", "Esrb", "<cmd>GoTag bson --rm <CR>", { desc = "Rm bson struct tags" })
  map("n", "Et", "<cmd>GoTest <CR>", { desc = "Run All tests" })

  map("n", "Ei", "<cmd>GoIfErr <CR>", { desc = "Add if error" })
  map("n", "EI", "<cmd>GoImpl <CR>", { desc = "Add Impl" })
  map("n", "Ef", "<cmd>GoFillStruct <CR>", { desc = "Go Fill Struct" })
  map("n", "Emt", "<cmd>GoModTidy", { desc = "Go mod tidy" })
  map("n", "Emi", "<cmd>GoModInit", { desc = "Go mod init" })
  map("n", "Eg", "<cmd>GoGenerate", { desc = "Go generate" })

  -- gopher
  -- map("n", "Esj", "<cmd>GoTagAdd json <CR>", { desc = "Add json struct tags" })
  -- map("n", "Esb", "<cmd>GoTagAdd bson <CR>", { desc = "Add bson struct tags" })
  -- map("n", "Esrj", "<cmd>GoTagRm json <CR>", { desc = "Rm json struct tags" })
  -- map("n", "Esrb", "<cmd>GoTagRm bson <CR>", { desc = "Rm bson struct tags" })
  -- map("n", "Ei", "<cmd>GoIfErr <CR>", { desc = "Add if error" })
  -- map("n", "EI", "<cmd>GoImpl <CR>", { desc = "Add Impl" })
  -- map("n", "Et", "<cmd>GoTestsAll <CR>", { desc = "Run All tests" })
  -- map("n", "Emt", "<cmd>GoMod tidy", { desc = "Go mod tidy" })
  -- map("n", "Emi", "<cmd>GoMod init", { desc = "Go mod init" })
  -- map("n", "Eg", "<cmd>Go generate", { desc = "Go generate" })

  vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.go",
    command = "GoImport"
  })
end
M.rust_analyzer = function()
  map("n", "Ei", ":RustToggleInlayHints<cr>", nor_s)
  map("n", "Er", ":RustRunnables<cr>", nor_s)
  map("n", "Ee", ":RustExpandMacro<cr>", nor_s)
  map("n", "Eo", ":RustOpenCargo<cr>", nor_s)
  map("n", "Ep", ":RustParentModule<cr>", nor_s)
  map("n", "Ej", ":RustJoinLines<cr>", nor_s)
  map("n", "Ep", ":RustParentModule<cr>", nor_s)
  map("n", "Eh", ":RustHoverActions<cr>", nor_s)
  map("v", "Eh", ":RustHoverRange<cr>", nor_s)
  map("n", "E<up>", ":RustMoveItemUp<cr>", nor_s)
  map("n", "E<down>", ":RustMoveItemDown<cr>", nor_s)
  map("n", "Es", ":RustStartStandaloneServerForBuffer<cr>", nor_s)
  map("n", "Ed", ":RustDebuggables<cr>", nor_s)
  map("n", "Ev", ":RustViewCrateGraph<cr>", nor_s)
  map("n", "ER", ":RustReloadWorkspace<cr>", nor_s)
  map("n", "ES", ":RustSSR<cr>", nor_s)
  map("n", "EO", ":RustOpenExternalDocs<cr>", nor_s)
end
return M
