-- neovim-project config (maintained fork of project.nvim)
require("neovim-project").setup({
  projects = {
    -- You can add specific project paths here, or leave empty for auto-discovery
    -- "~/projects/*",
    -- "~/work/*",
  },
  -- Patterns to detect project root
  picker = {
    type = "telescope",
  },
  -- Restore the last session on `nvim` startup (no args).
  -- Combined with the broader `sessionoptions` in config/settings.lua,
  -- this restores the previous window/buffer layout when re-opening a project.
  last_session_on_startup = true,
  dashboard_mode = false,
  -- File patterns to look for when detecting root directory
  datapath = vim.fn.stdpath("data"),
})

-- Load telescope extension
local ok, telescope = pcall(require, "telescope")
if ok then
  telescope.load_extension("neovim-project")
end
