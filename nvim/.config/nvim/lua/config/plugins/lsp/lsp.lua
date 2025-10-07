-- -----------
-- LSP
-- -----------
-- to choose version add a @<version> to the right of the name like hls@2.0.0.0
local servers = {
  "bashls",
  -- "pylyzer",
  -- "pylsp",
  "ruff",
  "basedpyright",
  "clangd",
  "html",
  "cssls",
  "ts_ls",
  "svelte",
  "lua_ls",
  "vimls",
  "gopls",
  "dockerls",
  "jsonls",
  "rust_analyzer",
  -- "volar",
  -- "eslint-lsp"
  -- "sqls",
  -- "hls@2.0.0.0", -- mason is not installing it correctly as of 10/06/23
  -- "hls", -- NOTE: breaking new installs
  "emmet_ls",
  "terraformls",
}


if os.getenv("NVIM_MINIMAL") ~= nil then
  servers = {}
end

vim.lsp.inlay_hint.enable = false
local default_opts = require("config.plugins.lsp.defaults_opts")
local get_lsp_opts = function()
  local opts = vim.deepcopy(default_opts)
  return {
    capabilities = opts.capabilities,
    handlers = opts.handlers,
    on_attach = opts.on_attach,
    -- inlay_hints = { enabled = false },
  }
end
local lang_opts = require("config.plugins.lsp.lang_opts")
local enhance_server = function(server, opts)
  if lang_opts.enhanceable(server) then
    lang_opts.enhance(server, opts)
  end
end

local handlers = {
  function(server_name)
    local opts = get_lsp_opts()
    enhance_server(server_name, opts)
    vim.lsp.config(server_name, opts)
  end,
  ["rust_analyzer"] = function() end,
  ["hls"] = function()
    -- local opts = get_opts()
    local opts = get_lsp_opts()
    enhance_server("hls", opts)

    if require("utils.lua.lazy").is_plugin_enabled("haskell-tools") then
      require("haskell-tools").setup({ hls = opts })
    else
      vim.lsp.config("hls", opts)
    end
  end,
  -- ["lua_ls"] = function()
  --   require("neodev").setup({})
  --   local opts = get_lsp_opts()
  --   enhance_server("lua_ls", opts)
  --   vim.lsp.config("lua_ls", opts)
  -- end,
}

-- set log level for lsp operations, probably what you want
-- vim.lsp.set_log_level("info")
-- TODO; change this
-- vim.lsp.set_log_level("trace")

require("mason").setup({
  -- by default the path is extended to here
  -- install_root_dir = path.concat { vim.fn.stdpath "data", "mason" },
  -- useful for package installation errors
  -- log_level = vim.log.levels.INFO,
  -- Where Mason should put its bin location in your PATH. Can be one of:
  -- - "prepend" (default, Mason's bin location is put first in PATH)
  -- - "append" (Mason's bin location is put at the end of PATH)
  -- - "skip" (doesn't modify PATH)
  ---@type '"prepend"' | '"append"' | '"skip"'
  PATH = "append", --default is prepend
})
require("mason-lspconfig").setup({
  ensure_installed = servers,
  --   - false: Servers are not automatically installed.
  --   - true: All servers set up via lspconfig are automatically installed.
  automatic_enable = true,
  handlers = handlers,
})
