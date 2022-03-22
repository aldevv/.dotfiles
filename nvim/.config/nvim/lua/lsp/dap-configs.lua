local M = {}

local dbg_path = require("dap-install.config.settings").options["installation_path"]
-- adapters should be general for the language, the configuration should be unique for what you
-- want, this includes the binary

local debug_opts = {
    -- default config --> https://github.com/Pocco81/DAPInstall.nvim/blob/main/lua/dap-install/core/debuggers/python.lua
    -- if no adapter, it uses default config
    ["python"] = function()
        return {
            --adapters don't have the ${} syntax
            -- adapters = {
            --     type = "executable",
            --     command = require("dap-install.config.settings").options["installation_path"] .. "python/bin/python",
            --     args = { "-m", "debugpy.adapter" },
            --     options = {
            --         env = {}, -- Set the environment variables for the command
            --         cwd = vim.fn.getcwd(), -- Set the working directory for the command
            --     },
            -- },
            configurations = {
                {
                    type = "python",
                    request = "launch",
                    name = "Python",
                    program = "${file}",
                    args = {},
                    subProcess = false,
                    -- settings --> https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings
                    --  https://code.visualstudio.com/docs/python/debugging#_debugging-specific-app-types
                    justMyCode = false, -- debug also goes into libraries
                    autoReload = {
                        enable = true,
                    },
                    pythonPath = function()
                        -- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
                        -- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
                        -- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
                        local venv_path = os.getenv("VIRTUAL_ENV")
                        if venv_path then
                            return venv_path .. "/bin/python"
                        end
                        return "/usr/bin/python"
                    end,
                },
                {
                    type = "python",
                    request = "launch",
                    name = "Django",
                    program = "${workspaceFolder}/manage.py",
                    args = { "runserver", "0.0.0.0:8000", "--noreload", "--nothreading" },
                    subProcess = false,
                    -- settings --> https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings
                    --  https://code.visualstudio.com/docs/python/debugging#_debugging-specific-app-types
                    django = true,
                    justMyCode = false, -- debug also goes into libraries
                    autoReload = {
                        enable = true,
                    },
                    pythonPath = function()
                        -- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
                        -- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
                        -- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
                        local cwd = vim.fn.getcwd()
                        if vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
                            return cwd .. "/.venv/bin/python"
                        else
                            return "/usr/bin/python"
                        end
                    end,
                },
            },
        }
    end,

    ["lua"] = function()
        return {
            configurations = {
                port = 3333,
            },
        }
    end,
}

function M.configExists(name)
    for key, _ in pairs(debug_opts) do
        if name == key then
            return true
        end
    end
    return false
end

function M.configurate(name)
    return debug_opts[name]()
end

return M
