-- checkout:
-- telescope.nvim
-- refactor.lua
-- navigator.lua
vim.opt.shadafile = "NONE" -- optimization
vim.cmd("set t_Co=256")
vim.cmd("let IS_MINE=isdirectory($SUCKLESS)")

--==================
-- SETTINGS
--==================
if os.getenv("DEBUG_VIM") then
    require("utils.lua.globals")
    require("config.pre-settings")
    require("plugins-debug")
    return
else
    require("utils.lua.globals")
    require("config.pre-settings")
    vim.cmd("source $XDG_CONFIG_HOME/nvim/modules/settings.vim")

    --==================
    -- KEYBINDINGS
    --==================
    vim.cmd("source $XDG_CONFIG_HOME/nvim/modules/keybindings.vim")
    if os.getenv("USER") == "root" then
        vim.cmd("source $XDG_CONFIG_HOME/nvim/modules/appearance.vim")
        vim.cmd("source $XDG_CONFIG_HOME/nvim/modules/automation.vim")
        return
    end
    --===================
    -- DEPENDENCIES
    --===================
    vim.cmd("source $XDG_CONFIG_HOME/nvim/modules/dependencies.vim")
    --==================
    -- PLUGINS
    --==================
    vim.cmd([[
    source $XDG_CONFIG_HOME/nvim/modules/plugins-settings.vim
  ]])
end
--==================
-- APPEARANCE
--==================
vim.cmd("source $XDG_CONFIG_HOME/nvim/modules/appearance.vim")

--==================
-- AUTOMATION
--==================
vim.cmd("source $XDG_CONFIG_HOME/nvim/modules/automation.vim")
--====================================================
-- require("plugins")
-- require("lsp")
-- require("core")
-- require("config")

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
