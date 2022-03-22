vim.o.guifont = "DaddyTimeMono Nerd Font,JoyPixels:h12"
vim.opt.exrc = true
-- https://vonheikemen.github.io/devlog/tools/configuring-neovim-using-lua/
-- neovide
vim.g.neovide_refresh_rate = 140
-- vim.g.neovide_transparency=1
--
-- vim.g.neovide_cursor_animation_length=0.13 -- in seconds
--let g:neovide_cursor_trail_length=0.8
-- vim.g.neovide_cursor_vfx_mode = "railgun" -- torpedo, pixiedust, sonicboom, ripple, wireframe
--vim.g.neovide_cursor_vfx_opacity=200.0 -- particle opacity
--vim.g.neovide_cursor_vfx_particle_density=7.0 -- particle density
--vim.g.neovide_cursor_vfx_particle_speed=10.0 -- particle speed
--vim.g.neovide_cursor_vfx_particle_phase=1.5 -- particle phase
--vim.g.neovide_cursor_vfx_particle_curl=1.0 -- particle curl

vim.o.grepprg = "rg --vimgrep --no-heading --smart-case"

-- netrw
vim.g.netrw_bufsettings = "noma nomod nu nowrap ro nobl" -- add line numbers
-- hide hidden files
vim.g.netrw_hide = 1
vim.g.netrw_winsize = "25%"
vim.g.netrw_banner = 0
-- for the help menu
vim.o.wildmenu = true
vim.o.wildmode = "full"

vim.o.backup = true
vim.o.undofile = true
vim.o.inccommand = "nosplit"
--Make backup before overwriting the current buffer
vim.o.writebackup = true
-- Overwrite the original backup file
vim.o.backupcopy = "no"
-- Meaningful backup name, ex: filename@2015-04-05.14:59
vim.cmd([[
    au BufWritePre * let &bex = "@" . strftime("%F.%H:%M")
]])
vim.o.backupdir = vim.fn.stdpath("cache") .. "/backups"
vim.o.undodir = vim.fn.stdpath("cache") .. "/undodir"
vim.o.autochdir = false -- for netrw

vim.opt.timeoutlen = 700
-- vim.g.mapleader = t("<Space>")
-- vim.g.maplocalleader=t("BS>")
