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
  last_session_on_startup = false,
  dashboard_mode = false,
  -- File patterns to look for when detecting root directory
  datapath = vim.fn.stdpath("data"),
})

-- Load telescope extension
local ok, telescope = pcall(require, "telescope")
if ok then
  telescope.load_extension("neovim-project")
end
