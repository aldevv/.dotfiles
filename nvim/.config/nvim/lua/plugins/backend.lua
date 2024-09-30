return {

  {
    "ray-x/go.nvim",
    -- commit = "a8095eb334495caec3099b717cc7f5b1fbc3e628",
    dependencies = { -- optional packages
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("go").setup({
        run_in_floaterm = false,
      })
    end,
    event = { "CmdlineEnter" },
    ft = { "go", "gomod" },
    build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
  },
  {
    "mrcjkb/rustaceanvim",
    version = "^3", -- Recommended
    init = function()
      vim.g.rustaceanvim = {
        -- -- Plugin configuration
        -- tools = {},
        -- -- LSP configuration
        server = {
          --   on_attach = function(client, bufnr)
          --     -- you can also put keymaps in here
          --   end,
          settings = {
            -- rust-analyzer language server configuration
            ["rust-analyzer"] = {
              checkOnSave = {
                command = "clippy",
              },
            },
          },
        },
        -- DAP configuration
        -- dap = {},
      }

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "rust",
        callback = function()
          vim.api.nvim_create_autocmd("LspAttach", {
            callback = function()
              local client = "rust_analyzer"
              require("keybindings.langs").load_mappings(client)
              require("keybindings.dap").load_mappings(client)
              require("keybindings.lsp").load_mappings()
            end,
          })
        end,
      })
    end,
    ft = { "rust" },
  },
  {
    "mrcjkb/haskell-tools.nvim",
    config = nil,
    branch = "2.x.x", -- recommended
    lazy = true,
  },
}
