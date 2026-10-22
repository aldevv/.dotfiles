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
  -- "html",
  "cssls",
  "ts_ls",
  "svelte",
  "lua_ls",
  "vimls",
  "gopls",
  "dockerls",
  "jsonls",
  "yamlls",
  "taplo",
  "rust_analyzer",
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

vim.lsp.log.set_level(vim.log.levels.OFF)
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

-- mason-lspconfig 2.x removed `handlers` and `automatic_installation`.
-- The new pattern: mason installs binaries, then we configure each server
-- ourselves via vim.lsp.config / vim.lsp.enable (nvim 0.11+).
local custom_setup = {
  ["rust_analyzer"] = function() end, -- owned by rustaceanvim
  ["pyright"] = function()
    print("[LSP] pyright skipped - using basedpyright instead")
  end,
  ["hls"] = function()
    local opts = get_lsp_opts()
    enhance_server("hls", opts)
    if require("utils.lua.lazy").is_plugin_enabled("haskell-tools") then
      require("haskell-tools").setup({ hls = opts })
    else
      vim.lsp.config["hls"] = opts
      vim.lsp.enable("hls")
    end
  end,
}

local function enable_server(server_name)
  local custom = custom_setup[server_name]
  if custom then
    custom()
    return
  end
  local opts = get_lsp_opts()
  enhance_server(server_name, opts)
  vim.lsp.config[server_name] = opts
  vim.lsp.enable(server_name)
end

local mason_registry = require("mason-registry")

-- A ~/.npmrc pointing at a private registry with an expired token makes every Mason npm
-- install fail with E401, so Mason installs always use public npm.
local running_installs = 0
mason_registry:on("package:install:handle", function()
  running_installs = running_installs + 1
  vim.uv.os_setenv("npm_config_registry", "https://registry.npmjs.org/")
end)
local function on_install_done()
  running_installs = running_installs - 1
  if running_installs == 0 then vim.uv.os_unsetenv("npm_config_registry") end
end
mason_registry:on("package:install:success", on_install_done)
mason_registry:on("package:install:failed", on_install_done)

local tools = { "stylua", "luacheck", "vint", "shfmt", "prettier", "clang-format", "sql-formatter" }
if os.getenv("NVIM_MINIMAL") ~= nil then
  tools = {}
end
mason_registry.refresh(function()
  for _, name in ipairs(tools) do
    local pkg = mason_registry.get_package(name)
    if not pkg:is_installed() and not pkg:is_installing() then pkg:install() end
  end
end)
require("mason-lspconfig").setup({
  ensure_installed = servers,
  -- 2.x default: automatic_enable = true, which calls vim.lsp.enable for
  -- every installed server. We turn it off so our enable_server() owns the
  -- vim.lsp.config setup for each server.
  automatic_enable = false,
})

for _, server in ipairs(servers) do
  enable_server(server)
end
