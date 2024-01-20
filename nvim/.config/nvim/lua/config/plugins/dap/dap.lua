-- dap NEEDS 2 things
-- adapter (executable that contains the debugger)
-- configuration (how you want it to run)

-- install a new adapter
-- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation

-- install a new configuration (:h dap-configuration)
-- https://code.visualstudio.com/docs/python/debugging#_set-configuration-options

-- TODO check https://github.com/mfussenegger/nvim-dap-python

local dap = require("dap")
-- default is info
local level = "info" -- trace, error, debug, info, warn
dap.set_log_level(level)

local servers = {
  "debugpy",
  "delve",
  "node-debug2-adapter",
}

-- handler names
-- https://github.com/jay-babu/mason-nvim-dap.nvim/blob/main/lua/mason-nvim-dap/mappings/source.lua
local handlers = {
  function(config)
    require("mason-nvim-dap").default_setup(config)
  end,
  -- for c use cpptools, out of the box
  node2 = function(config)
    config.adapters = {
      type = "executable",
      command = "node-debug2-adapter",
    }
    require("mason-nvim-dap").default_setup(config)
  end,
  python = function(config)
    require("dap-python").setup()
    require("dap-python").test_runner = "pytest"
    require("mason-nvim-dap").default_setup(config)
  end,
  delve = function(config)
    require("dap-go").setup()
    require("mason-nvim-dap").default_setup(config)
  end,
}

require("mason-nvim-dap").setup({
  automatic_installation = true,
  ensure_installed = servers,
  automatic_setup = true,
  handlers = handlers,
})

-- open dapui automatically
local dapui = require("dapui")
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end
-- autocompletion for repl
vim.cmd([[au FileType dap-repl lua require('dap.ext.autocompl').attach()]])

dap.defaults.fallback.external_terminal = {
  command = "st",
  args = { "-e" },
}
dap.defaults.fallback.force_external_terminal = false
dap.defaults.fallback.terminal_win_cmd = "50vsplit new"

-------------
-- adapters
-------------

-- NOTE:
-- until haskell plugin comes out, use own adapter
dap.adapters.haskell = {
  type = "executable",
  command = "haskell-debug-adapter",
  args = { "--hackage-version=0.0.33.0" },
}
--------------------------------------------------------
dapui.setup({
  icons = { expanded = "▾", collapsed = "▸" },
  mappings = {
    -- Use a table to apply multiple mappings
    expand = { "<CR>", "<2-LeftMouse>" },
    open = "o",
    remove = "d",
    edit = "l", -- Edit the value of a variable
    repl = "r", -- send variable to repl
  },
  layouts = {
    {
      elements = {
        "scopes",
        "breakpoints",
        "stacks",
        "watches",
      },
      size = 40,
      position = "left",
    },
    {
      elements = {
        "repl",
        "console",
      },
      size = 10,
      position = "bottom",
    },
  },
  floating = {
    max_height = nil, -- These can be integers or a float between 0 and 1.
    max_width = nil, -- Floats will be treated as percentage of your screen.
    border = "single", -- Border style. Can be "single", "double" or "rounded"
    mappings = {
      close = { "q", "<Esc>" },
    },
  },
  windows = { indent = 1 },
})

-- require("dapui").float_element(<element ID>, <optional settings>)

-- virtual text

require("nvim-dap-virtual-text").setup({
  enabled = true,                    -- enable this plugin (the default)
  enabled_commands = true,           -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
  highlight_changed_variables = true, -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
  highlight_new_as_changed = false,  -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
  show_stop_reason = true,           -- show stop reason when stopped for exceptions
  commented = false,                 -- prefix virtual text with comment string
  -- experimental features:
  virt_text_pos = "eol",             -- position of virtual text, see `:h nvim_buf_set_extmark()`
  all_frames = false,                -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
  virt_lines = false,                -- show virtual lines instead of virtual text (will flicker!)
  virt_text_win_col = nil,           -- position the virtual text at a fixed window column (starting from the first text column) ,
  -- e.g. 80 to position at column 80, see `:h nvim_buf_set_extmark()`
})

-- custom commands

local repl = require("dap.repl")
repl.commands = vim.tbl_extend("force", repl.commands, {
  -- Add a new alias for the existing .exit command
  exit = { "exit", ".exit", ".bye" },
  -- Add your own commands; run `.echo hello world` to invoke
  -- this function with the text "hello world"
  custom_commands = {
    [".echo"] = function(text)
      dap.repl.append(text)
    end,
    -- Hook up a new command to an existing dap function
    [".restart"] = dap.restart,
  },
})

local ok, telescope = pcall(require, "telescope")
if not ok then
  return
end
telescope.load_extension("dap")
