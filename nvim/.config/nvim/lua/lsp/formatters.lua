local null_ls = require("null-ls")
local formatting = null_ls.builtins.formatting
local diagnostics = null_ls.builtins.diagnostics
local completion = null_ls.builtins.completion
local code_actions = null_ls.builtins.code_actions

-- config docs
--https://github.com/jose-elias-alvarez/null-ls.nvim/blob/1e131a0b3f52eb812c7c07f5e24aee90c0ee8967/doc/CONFIG.md
--https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/SOURCES.md
--https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md

local opts = {
  debug = false,
  log = {
    enable = false,
    level = "warn",
    use_console = "async",
  },
  on_attach = function(nlient, bufnr) end,
}

local ensure_format_servers = {
  "prettier",
  "shfmt",
  "black",
  "clang_format",
}
local ensure_diagnostic_servers = {
  -- "shellcheck",
  "flake8",
  "vint", -- for vim
}
local ensure_code_actions = {
  -- "shellcheck",
  "gitsigns",
  "refactoring",
}

if os.getenv("NVIM_MINIMAL") ~= "" then
  ensure_format_servers = {}
  ensure_diagnostic_servers = {}
  ensure_code_actions = {}
end

local ensure_installed = vim.tbl_extend("force", ensure_format_servers, ensure_diagnostic_servers, ensure_code_actions)

local conf = {
  black = { formatting.black.with({ extra_args = { "--fast" } }) },
  stylua = { formatting.stylua.with({ extra_args = { "--indent-type", "Spaces", "--call_parentheses", "None" } }) },
  shfmt = { formatting.shfmt.with({
    extra_filetypes = { "zsh", "bash" },
  }) },
  -- shellcheck = { diagnostics.shellcheck.with({ extra_filetypes = { "zsh", "bash" } }) },
}

local handlers = {
  function(source_name, methods)
    if conf[source_name] == nil then
      require("mason-null-ls.automatic_setup")(source_name, methods)
      return
    end

    for _, v in ipairs(conf[source_name]) do
      null_ls.register(v)
    end
  end
}
require("mason-null-ls").setup({
  ensure_installed = ensure_installed,
  automatic_installation = true,
  handlers = handlers,
})

null_ls.setup(opts)
