local function req(module)
  return function(name, opts)
    require(module)
  end
end
return {
  {
    "mattn/emmet-vim",
    init = function()
      -- vim.g.user_emmet_install_global = 0
    end,
    config = function()
      vim.keymap.set("i", "€", "<plug>(emmet-expand-abbr)")
    end,
    ft = { "html", "js", "javascriptreact", "typescriptreact", "ts", "css", "vue", "svelte", "jsx", "tsx" },
  },
  {
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup()
    end
  },
  {
    "ziontee113/color-picker.nvim",
    config = function()
      require("color-picker").setup()
    end
  },
  {
    "windwp/nvim-ts-autotag",
    config = function()
      require('nvim-ts-autotag').setup()
    end
  },
}
