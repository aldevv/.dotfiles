-- get neotest namespace (api call creates or returns namespace)
local neotest_ns = vim.api.nvim_create_namespace("neotest")
vim.diagnostic.config({
    virtual_text = {
        format = function(diagnostic)
            local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
            return message
        end,
    },
}, neotest_ns)

require("neotest").setup({
    adapters = {
        -- require("neotest-python")({}), --  need to add env variable options
        require("neotest-vim-test")({}),
        require("neotest-go"),
        require("neotest-python")({
            -- Extra arguments for nvim-dap configuration
            -- See https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for values
            dap = { justMyCode = false },
            -- Command line arguments for runner
            -- Can also be a function to return dynamic values
            args = { "--log-level", "DEBUG" },
            -- Runner to use. Will use pytest if available by default.
            -- Can be a function to return dynamic value.
            runner = "pytest",
            -- Custom python path for the runner.
            -- Can be a string or a list of strings.
            -- Can also be a function to return dynamic value.
            -- If not provided, the path will be inferred by checking for
            -- virtual envs in the local directory and for Pipenev/Poetry configs
            -- python = ".venv/bin/python",
            -- Returns if a given file path is a test file.
            -- NB: This function is called a lot so don't perform any heavy tasks within it.
            -- is_test_file = function(file_path)
            --   ...
            -- end,
        }),
    },
    diagnostic = {
        enabled = true,
        severity = 1,
    },
    quickfix = {
        enabled = true,
        open = false,
    },
    status = {
        enabled = true,
        signs = true,
        virtual_text = false,
    },
    output = {
        enabled = true,
        open_on_run = "short",
    },
    output_panel = {
        enabled = true,
        -- open = "botright split | resize 15",
        open = "botright vsplit | vertical resize 55",
    },
    summary = {
        mappings = {
            attach = "a",
            clear_marked = "M",
            clear_target = "T",
            expand = { "<CR>", "<2-LeftMouse>" },
            expand_all = "E",
            jumpto = "i",
            mark = "m",
            output = "o",
            run = "r",
            run_marked = "R",
            short = "O",
            stop = "u",
            target = "t",
        },
    },
})
-- vim.diagnostic.config({}, vim.api.nvim_create_namespace("neotest"))

local s = { silent = true }
local nor = { noremap = true }

local nor_s = vim.tbl_extend("keep", nor, s)

local map = vim.keymap.set

local desc = function(desc)
    return vim.tbl_extend("keep", nor_s, { desc = desc })
end

-- https://github.com/nvim-neotest/neotest#usage
-- https://sourcegraph.com/github.com/nvim-neotest/neotest-go/-/blob/README.md?subtree=true
map("n", "<localleader>tp", ":lua require('neotest').output_panel.toggle()<cr>", desc("Test: output_panel"))
map("n", "<localleader>tn", ":lua require('neotest').run.run()<cr>", nor_s) -- run nearest
map("n", "<localleader>tx", ":lua require('neotest').run.stop()<cr>", nor_s) -- run nearest
map("n", "<localleader>tf", ":lua require('neotest').run.run(vim.fn.expand('%'))<cr>", nor_s)
map("n", "<localleader>ts", ":lua require('neotest').summary.toggle()<cr>", nor_s)
map("n", "<localleader>to", ":lua require('neotest').output.open({enter = false})<cr>", nor_s)
map("n", "<localleader>tO", ":lua require('neotest').output.open({enter = true})<cr>", nor_s)
map("n", "<localleader>tl", ":lua require('neotest').run.run_last()<cr>", nor_s)
map("n", "<localleader>tk", ":lua require('neotest').jump.next({status = 'failed'})<cr>", nor_s)
map("n", "<localleader>tK", ":lua require('neotest').jump.prev({status = 'failed'})<cr>", nor_s)
map("n", "<localleader>tt", ":lua require('neotest').run.run({suite = true})<cr>", nor_s)
map("n", "<localleader>tS", ":lua require('neotest').run.run({suite = true})<cr>", nor_s)
map("n", "<localleader>tg", ":TestVisit<cr>", nor_s)
vim.cmd([[cnoreabbrev Tn TestNearest]])
vim.cmd([[cnoreabbrev Ts TestSuite]])
vim.cmd([[cnoreabbrev Tf TestFile]])
vim.cmd([[cnoreabbrev Tl TestLast]])

-- map("n", "<leader>Tn", ":TestNearest<cr>", nor_s)
-- map("n", "<leader>Tf", ":TestFile<cr>", nor_s)
-- map("n", "<leader>Tt", ":TestSuite<cr>", nor_s)
-- map("n", "<leader>Tl", ":TestLast<cr>", nor_s)
-- map("n", "<leader>Tg", ":TestVisit<cr>", nor_s)
