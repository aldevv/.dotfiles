-- telescope.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

if os.getenv("DEBUG_NVIM") then
    require("lazy").setup("plugins-debug")
    return
end

-- refactor.lua
-- navigator.lua
-- NOTE: extract impatient to other file
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
vim.cmd("set t_Co=256")
vim.cmd("let IS_MINE=isdirectory($SUCKLESS)")
CONFIG_HOME = "~/.config"

require("utils.lua.globals")

if os.getenv("USER") == "root" then
    require("config.appearance")
    require("config.automation")
    return
end

-- require("lazy").setup("plugins")
require("lazy").setup("plugins", {
    dev = { path = "~/repos/github.com/rest-nvim", fallback = true, patterns = {} },
})

-- set theme
vim.cmd("colorscheme gruvbox")
-- transparency
vim.cmd("hi Normal guibg=NONE ctermbg=NONE")
require("config")
require("core")

-- vim.opt.shadafile = "" -- optimization
