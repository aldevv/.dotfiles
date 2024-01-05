local function req(module)
  return function(name, opts)
    require(module)
  end
end
return {
  {
    "neovim/nvim-lspconfig",
    config = req("lsp.lsp"),
    dependencies = {
      { "williamboman/mason.nvim", build = ":MasonUpdate" },
      "williamboman/mason-lspconfig.nvim",
      "folke/neodev.nvim",
      {
        "hrsh7th/nvim-cmp",
        config = req("lsp.cmp"),
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
            end
          },
        },
      },
    },
  },

  {
    "nvimtools/none-ls.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "williamboman/mason.nvim" },
    config = req("lsp.formatters"),
  },

  "jayp0521/mason-null-ls.nvim",
  {
    "ray-x/lsp_signature.nvim",
    config = req("lsp.lsp-signature"),
    dependencies = {
      "neovim/nvim-lspconfig",
      "hrsh7th/nvim-cmp",
    },
  },
  { "simrat39/rust-tools.nvim", lazy = true },
  {
    "mrcjkb/haskell-tools.nvim",
    config = nil,
    branch = "2.x.x", -- recommended
    lazy = true,
  },
}
