vim.cmd([[
filetype plugin on
set number nu
]])

vim.filetype.add({
	extension = {
		mdx = "markdown",
		keymap = "dts",
		ddl = "sql",
	},
	filename = {
		[".envrc"] = "bash",
		[".projections.json"] = "json",
		["launch.json"] = "jsonc",
		["docker-compose.json"] = "jsonc",
	},
})

-- split window will put the new window right of the current one
vim.opt.splitright = true
-- split window will put the new window below the current one
vim.opt.splitbelow = true
-- the title of the window will be set to the filepath
vim.opt.title = true
vim.opt.titlestring = '%{expand("%:p:~")}%a%r%m'

-- maximum width of text that is inserted, after which the text is broken
vim.opt.textwidth = 95

-- save folds and cursor position
vim.opt.viewoptions = "folds,cursor"
-- broader sessionoptions so :mksession / neovim-project actually restores layout
vim.opt.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,winpos,terminal"

-- enable trailing symbols eol symbol etc
vim.opt.list = true
vim.opt.listchars = "nbsp:⦸" -- CIRCLED REVERSE SOLIDUS (U+29B8, UTF-8: E2 A6 B8)
vim.opt.listchars = vim.opt.listchars + "tab:▷┅" -- WHITE RIGHT-POINTING TRIANGLE (U+25B7, UTF-8: E2 96 B7)
vim.opt.listchars = vim.opt.listchars + "extends:»" -- RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00BB, UTF-8: C2 BB)
vim.opt.listchars = vim.opt.listchars + "precedes:«" -- LEFT-POINTING DOUBLE ANGLE QUOTATION MARK (U+00AB, UTF-8: C2 AB)
vim.opt.listchars = vim.opt.listchars + "trail:•"
vim.opt.listchars = vim.opt.listchars + "eol:↲"
vim.opt.cursorline = true
vim.opt.cursorcolumn = true

-- expand tab to spaces
vim.opt.expandtab = true
-- enable smartcase when searching/substituting
vim.opt.ignorecase = true
vim.opt.smartcase = true
-- disable wrapping lines
vim.opt.wrap = false
-- disable swap files
vim.opt.swapfile = false
-- enable incremental search
vim.opt.incsearch = true
-- enable relative line numbers
vim.opt.relativenumber = true
-- make backspaces more powerfull
vim.opt.backspace = "indent,eol,start"
-- enable mouse support
vim.opt.mouse = "a"
-- confirm before exiting if there are unsaved changes
vim.opt.confirm = true
-- enable running exrc files in cwd
vim.opt.exrc = true

-- https://vonheikemen.github.io/devlog/tools/configuring-neovim-using-lua/
-- neovide
vim.o.guifont = "DaddyTimeMono Nerd Font,JoyPixels:h12"
vim.g.neovide_refresh_rate = 140

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
-- " set wildmode=longest,list,full

-- remove command line
vim.o.cmdheight = 0

-- remove --INSERT from the status line
vim.o.showmode = false

-- make unique status line for each buffer, if want global use 3, or the global option in
-- lualine
vim.o.laststatus = 2

vim.o.backup = true
vim.o.backupdir = vim.fn.stdpath("cache") .. "/backups"
vim.o.undofile = true
vim.o.undodir = vim.fn.stdpath("cache") .. "/undodir"
vim.o.inccommand = "nosplit"
--Make backup before overwriting the current buffer
vim.o.writebackup = true
-- Meaningful backup name, ex: filename@2015-04-05.14:59
vim.cmd([[
    au BufWritePre * let &bex = "@" . strftime("%F.%H:%M")
]])
vim.o.autochdir = false -- for netrw

-- add vertical line
vim.o.colorcolumn = "100"
-- colorcolumn transparent

vim.opt.updatetime = 250
vim.opt.timeoutlen = 700
-- ttimeoutlen=10 makes ESC and key chords feel snappy. default -1 follows
-- timeoutlen=700ms which is the dominant key-feel-lag source.
vim.opt.ttimeoutlen = 10
vim.opt.shiftwidth = 2

vim.opt.pumblend = 10
vim.opt.statusline = "%t"
-- spell is per-filetype below (markdown/text/gitcommit), not global, to keep
-- the spell sign-column out of source buffers.
vim.opt.spell = false

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("spell_per_filetype", { clear = true }),
  pattern = { "markdown", "text", "gitcommit", "asciidoc", "rst" },
  callback = function() vim.opt_local.spell = true end,
})

-- 0.11+: unified rounded border across hover/signature/diagnostic floats.
if vim.fn.has("nvim-0.11") == 1 then
  vim.o.winborder = "rounded"
end

-- general diagnostics
vim.diagnostic.config({
  virtual_text = {
    spacing = 2,
    -- severity_limit was deprecated; use `severity` instead.
    severity = { min = vim.diagnostic.severity.WARN },
  },
  -- update_in_insert has bug with cmp, ghost_text (from cmp) overlaps virual_text (from diagnostics)
  update_in_insert = false,
  float = {
    source = true,
    border = "rounded",
  },
})

vim.opt.jumpoptions = "stack"

-- python host: init.lua already sets python3_host_prog from $(which python3).
-- This block stays as a macunix-only override for the legacy python2 host;
-- nothing on linux uses it.
if vim.fn.has("macunix") == 1 then
  vim.g.python_host_prog = "/usr/local/bin/python"
  if vim.fn.executable("/usr/local/bin/python3") == 1 then
    vim.g.python3_host_prog = "/usr/local/bin/python3"
  end
end
