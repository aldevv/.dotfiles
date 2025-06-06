local M = {}
-- :h lspconfig-root-advanced
-- :h lspconfig-root-composition
local util = require("lspconfig.util")
local function copy(opts)
  local tmp = {}
  for k, v in pairs(opts) do
    tmp[k] = v
  end
  return tmp
end

local enhance_server_opts = {
  ["bashls"] = function(opts)
    opts.filetypes = { "sh", "zsh", "bash" }
  end,
  ["sqls"] = function(opts)
    local tmp = copy(opts)
    opts.on_attach = function(cl, bufnr)
      tmp.on_attach(cl, bufnr)
      require("sqls").on_attach(cl, bufnr)
      vim.keymap.set("n", "<cr>", "<cmd>SqlsExecuteQuery<cr>", { buffer = 0 })
    end
  end,
  ["ts_ls"] = function(opts)
    opts.root_dir = function(fname)
      return util.root_pattern("tsconfig.json")(fname)
          or util.root_pattern("package.json", "jsconfig.json", ".git", ".projections.json")(fname)
    end
  end,
  ["pylsp"] = function(opts)
    opts.settings = {
      pylsp = {
        plugins = {
          jedi_completion = {
            include_params = true, -- this line enables snippets
          },
        },
      },
    }
  end,
  ["rust_analyzer"] = function(opts)
    local tmp = copy(opts)
    opts.server = {
      capabilities = tmp.capabilities,
      handlers = tmp.handlers,
      on_attach = function(cl, bufnr)
        tmp.on_attach(cl, bufnr)
        -- hover
        vim.keymap.set("n", "+", require("rust-tools").hover_actions.hover_actions, { buffer = bufnr })
        -- Code action groups
        vim.keymap.set(
          "n",
          "<Leader>la",
          require("rust-tools").code_action_group.code_action_group,
          { buffer = bufnr }
        )
      end,
    }
    opts.on_attach = nil
    opts.handlers = nil
    opts.capabilities = nil
  end,
  ["bufls"] = function(opts)
    opts.root_dir = function(fname)
      pwd = vim.fn.getcwd()
      return pwd
    end
  end,
  ["clangd"] = function(opts)
    opts.filetypes = { "c", "cpp", "objc", "objcpp" }
    opts.capabilities.offsetEncoding = { "utf-16" }
  end,
  ["gopls"] = function(opts)
    -- https://github.com/golang/tools/blob/master/gopls/doc/vim.md
    -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
    opts.settings = {
      gopls = {
        --https://staticcheck.dev/docs/checks/
        staticcheck = true,
        codelenses = {
          generate = true,
          gc_details = false,
          tidy = true,
          upgrade_dependency = true,
          vendor = true,
        },
        usePlaceholders = false,
        completeUnimported = true,
        buildFlags = { "-tags=linux,windows,darwin" },
      },
      -- NOTE: enable golanci
      go = {
        lintTool = "golangci-lint",
      },
    }
    --     gopls = {
    --       -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md#code-lenses
    --       -- codelenses = { gc_details = false, generate = true, regenerate_cgo = true, tidy = true, upgrade_dependency = true, vendor = true },
    --       -- https://github.com/golang/tools/blob/master/gopls/doc/inlayHints.md
    --       -- hints = {},
    --       -- hints = {
    --       --   assignVariableTypes = true,
    --       --   compositeLiteralFields = true,
    --       --   compositeLiteralTypes = true,
    --       --   constantValues = true,
    --       --   functionTypeParameters = true,
    --       -- parameterNames = true,
    --       -- parameterNames = true,
    --       --   rangeVariableTypes = true,
    --       -- },
    --       completeUnimported = true,
    --       usePlaceholders = false, -- this fills when pressing enter on cmp
    --     },
  end,
  ["lua_ls"] = function(opts)
    -- opts.settings = {
    --   Lua = {
    --     version = "LuaJIT",
    --     diagnostics = {
    --       globals = { "vim" },
    --     },
    --   },
    -- }
  end,
  ["eslintls"] = function(opts)
    opts.settings = {
      format = {
        enable = true,
      },
    }
  end,
  ["hls"] = function(opts)
    opts.root_dir = function(filepath)
      return (
        util.root_pattern("hie.yaml", "stack.yaml", "cabal.project")(filepath)
        or util.root_pattern("*.cabal", "package.yaml")(filepath)
      )
    end
  end,
  ["basedpyright"] = function(opts)
    opts.settings = {
      basedpyright = {
        -- Using Ruff's import organizer
        -- disableOrganizeImports = true,
        analysis = {
          autoImportCompletions = true,
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          -- diagnosticMode = "workspace", -- slower but analyzes and auto completes for whole workspace
          diagnosticMode = "openFilesOnly", -- faster
          -- typeCheckingMode = "basic",       -- standard, strict, all, off, basic
          typeCheckingMode = "standard",    -- standard, strict, all, off, basic
        },
      },
      python = {
        analysis = {
          -- Ignore all files for analysis to exclusively use Ruff for linting
          ignore = { '*' },
        },
      },
    }
  end,
  ["ruff"] = function(opts)
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup('lsp_attach_disable_ruff_hover', { clear = true }),
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client == nil then
          return
        end
        if client.name == 'ruff' then
          -- Disable hover in favor of basedpyright
          client.server_capabilities.hoverProvider = false
        end
      end,
      desc = 'LSP: Disable hover capability from Ruff',
    })
    opts.init_options = {
      settings = {
        logLevel = "info",
        -- logFile = "/tmp/ruff.log"
      }
    }
  end,
}
function M.enhanceable(name)
  for key, _ in pairs(enhance_server_opts) do
    if name == key then
      return true
    end
  end
  return false
end

function M.enhance(name, opts)
  enhance_server_opts[name](opts)
end

return M
