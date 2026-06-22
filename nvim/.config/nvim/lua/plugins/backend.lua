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
      },
      textobjects = false,
    },
    -- https://github.com/ray-x/go.nvim?tab=readme-ov-file#configuration
    config = function(lp, opts)
      require("go").setup(opts)
      -- Format-on-save for Go is owned by gopls via the format_on_save
      -- autocmd in lua/config/automation/init.lua. go.format.goimports
      -- ran simultaneously here and clobbered cursor position; removed.
    end,
    ft = { "go", "gomod" },
    build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
  },
  {
    "mrcjkb/rustaceanvim",
    version = "^5", -- v5 changed settings shape (default_settings, checkOnSave bool)
    init = function()
      vim.g.rustaceanvim = {
        server = {
          default_settings = {
            ["rust-analyzer"] = {
              -- v5: checkOnSave is now a bool; per-tool config lives under `check`.
              checkOnSave = true,
              check = { command = "clippy" },
            },
          },
        },
        -- tools = {}, dap = {},
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
