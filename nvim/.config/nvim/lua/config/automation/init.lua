require("config.automation.filetypes")

local has = function(bin) return vim.fn.executable(bin) == 1 end

-- Named augroups: every group uses `clear = true` so reloading this file
-- (e.g. :source %) replaces autocmds instead of stacking duplicates.
local g = function(name) return vim.api.nvim_create_augroup(name, { clear = true }) end

-- ============================================================================
-- suckless-build helpers (gated by binaries that only exist on the dwm host)
-- ============================================================================
vim.cmd([[
    function CompileSuck()
        let _path = expand('%:p:h')
        let name = system('basename '.shellescape(_path))
        if name =~ "dwm"
            echo name
            :exec '!changeWallpaperKeepBorders'
        else
            :exec 'cd '. _path
            :exec '!sudo make PREFIX=$HOME/.local/builds/st clean install '
        endif
    endfunction
]])

vim.api.nvim_create_autocmd("BufWritePost", {
  group = g("compile_suck"),
  pattern = "config.h",
  callback = function()
    if not has("changeWallpaperKeepBorders") and not has("sudo") then return end
    vim.cmd("call CompileSuck()")
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = g("compile_dwmstatus"),
  pattern = "dwmstatus",
  callback = function()
    if not has("dwmstatus") then return end
    vim.cmd("!killall dwmstatus; setsid dwmstatus &")
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = g("compile_xresources"),
  pattern = "*.Xresources",
  callback = function()
    if not has("xrdb") then return end
    vim.cmd("!xrdb -merge ~/.Xresources")
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = g("compile_sxhkd"),
  pattern = "*sxhkdrc",
  callback = function()
    if not has("sxhkd") then return end
    vim.cmd("!killall -s SIGUSR1 sxhkd")
  end,
})

-- ============================================================================
-- trailing-whitespace strip on save (per-buffer filetype, not load-time ext)
-- ============================================================================
vim.api.nvim_create_autocmd("BufWritePre", {
  group = g("strip_trailing_ws"),
  pattern = { "*.vim", "*.lua" },
  callback = function()
    local save = vim.fn.winsaveview()
    vim.cmd([[silent! %s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

-- ============================================================================
-- highlight yank
-- ============================================================================
vim.api.nvim_create_autocmd("TextYankPost", {
  group = g("highlight_yank"),
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 40 })
  end,
})

-- ============================================================================
-- macros over visual range (\@ binding)
-- ============================================================================
vim.cmd([[
  function! ExecuteMacroOverVisualRange()
    echo "@".getcmdline()
    execute ":'<,'>normal @".nr2char(getchar())
  endfunction
]])
vim.keymap.set("x", "@", ":<C-u>call ExecuteMacroOverVisualRange()<cr>")

-- ============================================================================
-- shortcut-regen autocmd (only when the helper exists)
-- ============================================================================
vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged" }, {
  group = g("auto_shortcuts"),
  pattern = { "sf", "sd" },
  callback = function()
    local automation = os.getenv("AUTOMATION")
    if not automation or vim.fn.executable(automation .. "/shortcuts") == 0 then return end
    vim.cmd("!$AUTOMATION/shortcuts")
  end,
})

-- ============================================================================
-- notes regen (Dispatch is lazy-loaded; this just queues the cmd)
-- ============================================================================
local notes_path = os.getenv("NOTES")
if notes_path and notes_path ~= "" then
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = g("notes_regen"),
    pattern = notes_path .. "/*.md",
    command = "Dispatch! . _dgp $NOTES $(stamp)",
  })
end

-- ============================================================================
-- LSP attach quirks
-- ============================================================================
vim.api.nvim_create_autocmd("LspAttach", {
  group = g("dwm_config_no_lsp"),
  pattern = "*/dwm-flexipatch/config.h",
  command = "LspStop",
})

-- ============================================================================
-- UI tweaks per filetype
-- ============================================================================
vim.api.nvim_create_autocmd("FileType", {
  group = g("telescope_ui"),
  pattern = { "TelescopePrompt*", "TelescopeResults" },
  command = "setlocal nocursorline",
})

vim.api.nvim_create_autocmd("TermOpen", {
  group = g("term_ui"),
  pattern = "*",
  command = "setlocal nospell",
})

vim.api.nvim_create_autocmd("FileType", {
  group = g("react_no_spell"),
  pattern = { "javascriptreact", "typescriptreact" },
  command = "setlocal nospell",
})

vim.api.nvim_create_autocmd("BufRead", {
  group = g("envrc_bash"),
  pattern = ".envrc",
  command = "set ft=bash",
})

vim.api.nvim_create_autocmd("BufRead", {
  group = g("keymap_dts"),
  pattern = "*.keymap",
  callback = function()
    vim.bo.syntax = "dts"
    vim.opt_local.formatoptions:remove({ "r", "o", "t" })
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  group = g("no_autocomment_continuation"),
  pattern = "*",
  callback = function()
    vim.opt_local.formatoptions:remove({ "r", "o", "t" })
  end,
})

-- ============================================================================
-- large file handling (>1 MB): disable LSP, folding, swap.
-- treesitter is disabled separately via the disable function in treesitter.lua.
-- gitsigns also keys off `vim.b.bigfile`.
-- ============================================================================
local bigfile_threshold = 1024 * 1024
vim.api.nvim_create_autocmd("BufReadPre", {
  group = g("bigfile_pre"),
  callback = function(args)
    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
    if ok and stats and stats.size > bigfile_threshold then
      vim.b[args.buf].bigfile = true
      vim.bo[args.buf].swapfile = false
    end
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = g("bigfile_post"),
  callback = function(args)
    if not vim.b[args.buf].bigfile then return end
    vim.wo[0].foldmethod = "manual"
    vim.wo[0].foldenable = false
    vim.schedule(function()
      for _, client in ipairs(vim.lsp.get_clients({ bufnr = args.buf })) do
        vim.lsp.buf_detach_client(args.buf, client.id)
      end
    end)
  end,
})

-- ============================================================================
-- format-on-save (NOTE: race with backend.lua's go.format.goimports; gopls is
-- now the single source of truth for Go, the other autocmd is removed.)
-- ============================================================================
local format_patterns = "*.{js,jsx,mjs,java,c,cpp,hs,json,ts,tsx,rs,go,html,svelte,vue,py,sh,lua,tf,tfvars}"
vim.api.nvim_create_autocmd("BufWritePre", {
  group = g("format_on_save"),
  pattern = format_patterns,
  callback = function(args)
    if vim.b[args.buf].bigfile then return end
    vim.lsp.buf.format({ timeout_ms = 3000, bufnr = args.buf })
  end,
})

-- ============================================================================
-- python type-parameter color reset
-- ============================================================================
vim.api.nvim_create_autocmd("BufEnter", {
  group = g("python_self_hl"),
  pattern = "*.py",
  callback = function()
    -- to show self in a different color than white
    -- you can check it with :Inspect
    vim.api.nvim_set_hl(0, "@lsp.type.parameter.python", {})
  end,
})
