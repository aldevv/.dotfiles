-- if you want to disable the plugin for a project
-- add this .nvim.lua --> require("project_nvim").setup({manual_mode=true})


require("project_nvim").setup({
  -- Manual mode doesn't automatically change your root directory, so you have
  -- the option to manually do so using `:ProjectRoot` command.
  manual_mode = false,
  -- manual_mode = true,
  -- Methods of detecting the root directory. **"lsp"** uses the native neovim
  -- lsp, while **"pattern"** uses vim-rooter like glob pattern matching. Here
  -- order matters: if one is not detected, the other is used as fallback. You
  -- can also delete or rearangne the detection methods.
  detection_methods = { "lsp", "pattern" },
  -- All the patterns used to detect root dir, when **"pattern"** is in
  -- detection_methods
  patterns = { ".projections.json", "go.mod", "Makefile", "package.json", "stack.yaml", ".git", "pyproject.toml" },
  -- Table of lsp clients to ignore by name
  -- eg: { "efm", ... }
  ignore_lsp = { "null-ls", "terraformls", "tflint" },
  -- Don't calculate root dir on specific directories
  -- Ex: { "~/.cargo/*", ... }
  exclude_dirs = {},
  -- Show hidden files in telescope
  show_hidden = false,
  -- When set to false, you will get a message when project.nvim changes your
  -- directory.
  silent_chdir = true,
  -- silent_chdir = false,
  -- Path where project.nvim will store the project history for use in
  -- telescope
  datapath = vim.fn.stdpath("data"),
})

local ok, telescope = pcall(require, "telescope")
if not ok then
  return
end
telescope.load_extension("projects") -- this is in the lsp modulwe
