vim.loader.enable()

-- install lazy
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


require("utils.lua.globals")
if os.getenv("USER") == "root" then
  require("config.appearance")
  require("config.automation")
  return
end

require("lazy").setup("plugins", {
  dev = { path = "~/repos/github.com/rest-nvim", fallback = true, patterns = {} },
})
require("config")
