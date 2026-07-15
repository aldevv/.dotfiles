if vim.loader then
  vim.loader.enable()
end

-- Disable built-in plugins that auto-load. Setting these before runtime
-- plugin sourcing prevents `netrw.vim`, `matchparen.vim`, etc. from running.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_tar = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_zip = 1
vim.g.loaded_gzip = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_remote_plugins = 1

-- Treat .h files as C, not C++ (suckless config.h, plain C headers).
vim.g.c_syntax_for_h = 1

-- Disable language-host providers we don't use; without this, nvim probes
-- $PATH for each on startup.
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
-- Pin python3 host explicitly so the provider sniff is skipped.
do
  local py3 = vim.fn.exepath("python3")
  if py3 ~= "" then
    vim.g.python3_host_prog = py3
  end
end

-- set Normal to no-bg BEFORE any plugin paints, so the terminal background
-- (transparency) shows on the very first frame, not just after tokyonight loads.
vim.cmd([[
  highlight Normal      ctermbg=NONE guibg=NONE
  highlight NonText     ctermbg=NONE guibg=NONE
  highlight SignColumn  ctermbg=NONE guibg=NONE
  highlight EndOfBuffer ctermbg=NONE guibg=NONE
]])

-- install lazy
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
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

require("config")

require("lazy").setup("plugins", {
	dev = { path = "~/repos/github.com/aldevv", fallback = true, patterns = {} },
})

require("keybindings")
require("ui")
