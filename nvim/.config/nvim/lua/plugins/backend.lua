return {

  {
    "ray-x/go.nvim",
    commit = "a3455f48cff718a86275115523dcc735535a13aa",
    dependencies = { -- optional packages
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      lsp_inlay_hints = {
        enable = false, -- this is the only field apply to neovim > 0.10
      }
    },
    -- https://github.com/ray-x/go.nvim?tab=readme-ov-file#configuration
    config = function(lp, opts)
      require("go").setup(opts)
      local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.go",
        callback = function()
          require('go.format').goimports()
        end,
        group = format_sync_grp,
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
  {
    "hexdigest/go-enhanced-treesitter.nvim",
    ft = "go",
  },
}
