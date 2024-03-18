vim.cmd("noremap S <Nop>")
local wk = require("which-key")
wk.register({
  S = {
    name = "Programming utils",
    d = { name = "DAP" },
    b = { name = "DBUI" },
    t = { name = "NeoTest" },
  },
})

local function source_tests_env()
  local tests_env = ".envtests"
  if vim.fn.filereadable(tests_env) == 1 then
    vim.cmd("Dotenv " .. tests_env)
  end
  if vim.fn.filereadable("../" .. tests_env) == 1 then
    vim.cmd("Dotenv ../" .. tests_env)
  end
end

-- neotest
vim.keymap.set("n", "<leader>n", function()
  source_tests_env()
  require("neotest").run.run()
  -- require("neotest").run.run({ extra_args = { "-v" } })
end, { desc = "run nearest test" })

vim.keymap.set("n", "<leader>N", function()
  source_tests_env()
  require("neotest").run.run({ strategy = "dap" })
end, { desc = "run nearest test with dap" })

vim.keymap.set("n", "<leader>e", function()
  source_tests_env()
  require("neotest").output.open({ enter = true })
end, { desc = "open test hover" })
vim.keymap.set("n", "<leader>N", ":lua require('neotest').run.run({suite=true})<cr>")
vim.cmd([[cnoreabbrev Tn TestNearest]])
vim.cmd([[cnoreabbrev Ts TestSuite]])
vim.cmd([[cnoreabbrev Tf TestFile]])
vim.cmd([[cnoreabbrev Tl TestLast]])

vim.keymap.set("n", "Stp", ":lua require('neotest').output_panel.toggle()<cr>", { desc = "Test: output_panel" })
vim.keymap.set("n", "Stn", ":lua require('neotest').run.run()<cr>")  -- run nearest
vim.keymap.set("n", "Stx", ":lua require('neotest').run.stop()<cr>") -- run nearest
vim.keymap.set("n", "Stf", ":lua require('neotest').run.run(vim.fn.expand('%'))<cr>")
vim.keymap.set("n", "Sts", ":lua require('neotest').summary.toggle()<cr>")
vim.keymap.set("n", "Sto", ":lua require('neotest').output.open({enter = true})<cr>")
vim.keymap.set("n", "StO", ":lua require('neotest').output.open({enter = false})<cr>")
vim.keymap.set("n", "Stl", ":lua require('neotest').run.run_last()<cr>")
vim.keymap.set("n", "Stk", ":lua require('neotest').jump.next({status = 'failed'})<cr>")
vim.keymap.set("n", "StK", ":lua require('neotest').jump.prev({status = 'failed'})<cr>")
vim.keymap.set("n", "Stt", ":lua require('neotest').run.run({suite = true})<cr>")
vim.keymap.set("n", "StS", ":lua require('neotest').run.run({suite = true})<cr>")
vim.keymap.set("n", "Stg", ":TestVisit<cr>")

-- dadbod
vim.keymap.set("n", "Sb", ":tabedit | DBUI<cr>")
vim.keymap.set("n", "SBd", ":DBUIToggle<cr>")
vim.keymap.set("n", "SBa", ":DBUIAddConnection<cr>")
vim.keymap.set("n", "SBf", ":DBUIFindBuffer<cr>")
vim.keymap.set("n", "SBq", ":DBUILastQueryInfo<cr>")

-- cody
vim.keymap.set({ "n", "x" }, "Sc", "<cmd>CodyChat<cr>", { desc = "Cody Chat" })
vim.keymap.set({ "n", "x" }, "SCr", "<cmd>CodyTask<cr>", { desc = "Cody Task perform a task on selected text." })
vim.keymap.set({ "n", "x" }, "SCt", "<cmd>CodyToggle<cr>", { desc = "CodyToggle" })
vim.keymap.set({ "n", "x" }, "SCn", "<cmd>CodyTaskNext<cr>", { desc = "CodyTaskNext" })
vim.keymap.set({ "n", "x" }, "SCe", "<cmd>CodyTaskPrev<cr>", { desc = "CodyTaskPrev" })
vim.keymap.set({ "n", "x" }, "SCR", "<cmd>CodyRestart<cr>", { desc = "CodyRestart" })

vim.keymap.set(
  { "n", "x" },
  "SCa",
  "<cmd>CodyAsk<cr>",
  { desc = "CodyAsk Ask a question about the current selection." }
)

vim.keymap.set(
  "n",
  "Sg",
  "<cmd>lua require('sg.extensions.telescope').fuzzy_search_results()<CR>",
  { desc = "Sourcegraph search" }
)
