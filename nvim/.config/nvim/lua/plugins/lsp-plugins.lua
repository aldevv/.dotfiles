local function req(module)
  return function(name, opts)
    require(module)
  end
end
return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = req("config.plugins.lsp.lsp"),
    dependencies = {
      { "mason-org/mason.nvim",           version = "^2.0", cmd = { "Mason", "MasonInstall", "MasonUpdate" } },
      { "mason-org/mason-lspconfig.nvim", version = "^2.0" },
      {
        'saghen/blink.cmp',
        dependencies = { 'rafamadriz/friendly-snippets',
          "onsails/lspkind-nvim",
          "folke/lazydev.nvim",
        },
        version = '*',
        event = "InsertEnter",
        config = req("config.plugins.lsp.blink"),
      },
    },
  },
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  -- conform.nvim and nvim-lint live in their own spec files
  -- (lua/plugins/conform.lua, lua/plugins/lint.lua) so they're easy to
  -- edit/disable independently of the lsp-plugins block.
  {
    "ray-x/lsp_signature.nvim",
    event = "LspAttach",
    config = req("config.plugins.lsp.lsp-signature"),
    dependencies = {
      "neovim/nvim-lspconfig",
    },
  },
}
