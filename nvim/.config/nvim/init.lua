if vim.loader then
  vim.loader.enable()
end

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

require("utils.lua.globals")
if os.getenv("USER") == "root" then
  vim.g.mapleader = require("utils.lua.misc").replace_termcodes("<Space>")
	require("ui")
	require("config.automation")
	require("keybindings")
	return
end

if os.getenv("NVIM_DEBUG") then
	require("lazy").setup("plugins-debug")
	return
end

do
	local p = vim.fn.expand("~/repos/github.com/aldevv/keymap-tracker.nvim")
	if (vim.uv or vim.loop).fs_stat(p) then
		vim.opt.rtp:prepend(p)
		pcall(function() require("keymap-tracker").setup() end)
	end
end

require("config")

require("lazy").setup("plugins", {
	dev = { path = "~/repos/github.com/aldevv", fallback = true, patterns = {} },
})

require("keybindings")
require("ui")
