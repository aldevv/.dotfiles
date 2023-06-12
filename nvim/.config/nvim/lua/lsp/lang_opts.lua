local M = {}
-- :h lspconfig-root-advanced
-- :h lspconfig-root-composition
local util = require("lspconfig.util")
local configs = require("lspconfig.configs")
local nvim_paths = vim.tbl_extend(
  "keep",
  vim.api.nvim_get_runtime_file("", true),
  { vim.fn.expand("$VIMRUNTIME/lua/vim"), vim.fn.expand("$VIMRUNTIME/lua/vim/lsp") }
)

function copy(opts)
  local tmp = {}
  for k, v in pairs(opts) do
    tmp[k] = v
  end
  return tmp
end

local runtime_path = vim.split(package.path, ";")
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")

-- local runtime_path = vim.split(package.path, ";")
-- table.insert(runtime_path, "lua/?.lua")
-- table.insert(runtime_path, "lua/?/init.lua")
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
  ["tsserver"] = function(opts)
    -- :h lspconfig-root-advanced
    -- :h lspconfig-root-composition
    -- root_dir is a function
    --
    -- :h lspconfig-root-dir
    opts.root_dir = function(fname)
      return util.root_pattern("tsconfig.json")(fname)
          or util.root_pattern("package.json", "jsconfig.json", ".git", ".projections.json")(fname)
    end
  end,
  ["pyright"] = function(opts)
    local tmp = copy(opts)
    opts.on_attach = function(client, bufnr)
      tmp.on_attach(client, bufnr)
      -- TODO: move this to keybindings.languages
      vim.keymap.set(
        "n",
        "<localleader>dlm",
        "<cmd>lua require('dap-python').test_method()<cr>",
        { noremap = true, silent = true }
      )
      vim.keymap.set(
        "n",
        "<localleader>dlc",
        "<cmd>lua require('dap-python').test_class()<cr>",
        { noremap = true, silent = true }
      )
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
  ["clangd"] = function(opts)
    opts.capabilities.offsetEncoding = { "utf-16" }
  end,
  ["gopls"] = function(opts)
    opts.settings = {
      gopls = {
        usePlaceholders = true,
      },
    }
  end,
  -- end,
  ["lua_ls"] = function(opts)
    opts.root_dir = util.root_pattern("apm.csv") or util.path.dirname(fname)
    opts.settings = {
      Lua = {
        runtime = {
          path = runtime_path,
        },
        diagnostics = {
          globals = { "vim" },
        },
        workspace = {
          library = nvim_paths,
          checkThirdParty = false,
        },
      },
    }
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
