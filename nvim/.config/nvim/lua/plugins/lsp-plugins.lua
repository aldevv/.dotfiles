local function req(module)
  return function(name, opts)
    require(module)
  end
end
return {
  {
    "neovim/nvim-lspconfig",
    config = req("config.plugins.lsp.lsp"),
    dependencies = {
      { "williamboman/mason.nvim", build = ":MasonUpdate" },
      "williamboman/mason-lspconfig.nvim",
      {
        'saghen/blink.cmp',
        dependencies = { 'rafamadriz/friendly-snippets',
          "saadparwaiz1/cmp_luasnip",
          "onsails/lspkind-nvim",
          "folke/lazydev.nvim",
        },
        version = '*',
        config = req("config.plugins.lsp.blink"),
      },

      {
        "hrsh7th/nvim-cmp",
        config = req("config.plugins.lsp.cmp"),
        dependencies = {
          "saadparwaiz1/cmp_luasnip",
          "nvim-lua/plenary.nvim",
          "onsails/lspkind-nvim",
          "hrsh7th/cmp-nvim-lsp",
          -- { "hrsh7th/cmp-nvim-lua",   ft = "lua" },
          "hrsh7th/cmp-path",
          "hrsh7th/cmp-buffer",
          "hrsh7th/cmp-cmdline",
          "petertriho/cmp-git",
          {
            "tzachar/cmp-fuzzy-path",
            dependencies = "tzachar/fuzzy.nvim",
            enabled = function()
              return vim.loop.os_uname().sysname == "Linux"
            end,
          },
        },
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
  {
    "nvimtools/none-ls.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "williamboman/mason.nvim" },
    config = req("config.plugins.lsp.formatters"),
  },

  "jayp0521/mason-null-ls.nvim",
  {
    "ray-x/lsp_signature.nvim",
    config = req("config.plugins.lsp.lsp-signature"),
    dependencies = {
      "neovim/nvim-lspconfig",
      "hrsh7th/nvim-cmp",
    },
  },
}
