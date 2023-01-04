-- telescope.nvim
if os.getenv("DEBUG") then
    require("plugins-debug")
    return
end

-- refactor.lua
-- navigator.lua
function loadrequire(module)
    local function requiref(module)
        -- require(module).enable_profile()
        require(module)
    end

    res = pcall(requiref, module)
    if not res then
        -- Do Stuff when no module
    end
end

loadrequire("impatient")
vim.opt.shadafile = "NONE" -- optimization
vim.cmd("set t_Co=256")
vim.cmd("let IS_MINE=isdirectory($SUCKLESS)")
CONFIG_HOME = "~/.config"

require("utils.lua.globals")
require("config.pre-settings")

if os.getenv("USER") == "root" then
    require("config.appearance")
    require("config.automation")
    return
end
--===================
-- DEPENDENCIES
--===================
-- vim.cmd("source ~/.config/nvim/modules/dependencies.vim")

local init_modules = {
    "plugins",
    "lsp",
    "config",
}

local sys_modules = {
    "core",
}

for i = 1, #init_modules, 1 do
    local ok, res = xpcall(require, debug.traceback, init_modules[i])
    if not ok then
        print("NVDope [E0]: There was an error loading the module '" .. init_modules[i] .. "' -->")
        print(res)
    end
end

local async
async = vim.loop.new_async(vim.schedule_wrap(function()
    for i = 1, #sys_modules, 1 do
        local ok, res = xpcall(require, debug.traceback, sys_modules[i])
        if not ok then
            print("NVDope [E0]: There was an error loading the module '" .. sys_modules[i] .. "' -->")
            print(res)
        end
    end
    async:close()
end))
vim.opt.shadafile = "" -- optimization
