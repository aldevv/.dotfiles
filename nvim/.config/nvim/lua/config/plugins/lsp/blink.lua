local cmp = require('blink.cmp')


cmp.setup({
  sources = {
    default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer' },
    providers = {
      lazydev = {
        name = "LazyDev",
        module = "lazydev.integrations.blink",
        -- make lazydev completions top priority (see `:h blink.cmp`)
        score_offset = 100,
      },
    },
  },
  keymap = {
    ["<D-c>"] = { "show" },
    ["<S-CR>"] = { "hide" },
    ["<CR>"] = { "select_and_accept", "fallback" },
    -- ["<Tab>"] = { "select_next", "fallback" },
    -- ["<S-Tab>"] = { "select_prev", "fallback" },
    ["<Down>"] = { "select_next", "fallback" },
    ["<Up>"] = { "select_prev", "fallback" },
    ["<C-n>"] = { "select_next", "fallback" },
    ["<C-p>"] = { "select_prev", "fallback" },

    ["<C-d>"] = { function()
      if not cmp.is_menu_visible() then return end
      vim.schedule(function(opts)
        for i = 1, 3, 1 do
          require('blink.cmp.completion.list').select_next(opts)
        end
      end)
      return true
    end, "fallback" },
    ["<C-u>"] = { function()
      if not cmp.is_menu_visible() then return end
      vim.schedule(function(opts)
        for i = 1, 3, 1 do
          require('blink.cmp.completion.list').select_prev(opts)
        end
      end)
      return true
    end, "fallback" },
    ["<PageDown>"] = { "scroll_documentation_down" },
    ["<PageUp>"] = { "scroll_documentation_up" },

  },
  appearance = {
    use_nvim_cmp_as_default = true,
    nerd_font_variant = 'mono'
  },
  fuzzy = { implementation = "prefer_rust_with_warning" },
  completion = {
    menu = {
      draw = {
        columns = {
          { "kind_icon", "label", "label_description", gap = 1 },
          { "kind" }
        },
        components = {

          -- kind_icons = {
          --   -- Text = "",
          --   Method = "󰊕",
          --   Function = "󰊕",
          --   Constructor = "",
          --   Field = "󰇽",
          --   Variable = "󰂡",
          --   Class = "󰜁",
          --   Interface = "",
          --   Module = "",
          --   Property = "󰜢",
          --   Unit = "",
          --   Value = "󰎠",
          --   Enum = "",
          --   Keyword = "󰌋",
          --   Snippet = "󰒕",
          --   Color = "󰏘",
          --   Reference = "",
          --   File = "",
          --   Folder = "󰉋",
          --   EnumMember = "",
          --   Constant = "󰏿",
          --   Struct = "",
          --   Event = "",
          --   Operator = "󰆕",
          --   TypeParameter = "󰅲",
          -- },
          -- lspkind
          kind_icon = {
            ellipsis = false,
            text = function(ctx)
              local lspkind = require("lspkind")
              local icon = ctx.kind_icon
              if vim.tbl_contains({ "Path" }, ctx.source_name) then
                local dev_icon, _ = require("nvim-web-devicons").get_icon(ctx.label)
                if dev_icon then
                  icon = dev_icon
                end
              else
                icon = require("lspkind").symbolic(ctx.kind, {
                  mode = "symbol",
                })
              end

              return icon .. ctx.icon_gap
            end,

            -- Optionally, use the highlight groups from nvim-web-devicons
            -- You can also add the same function for `kind.highlight` if you want to
            -- keep the highlight groups in sync with the icons.
            highlight = function(ctx)
              local hl = ctx.kind_hl
              if vim.tbl_contains({ "Path" }, ctx.source_name) then
                local dev_icon, dev_hl = require("nvim-web-devicons").get_icon(ctx.label)
                if dev_icon then
                  hl = dev_hl
                end
              end
              return hl
            end,
          }
          -- kind_icons = {
          --   Text = "[Text]",
          --   Method = "[Method]",
          --   Function = "[Function]",
          --   Constructor = "[Constructor]",
          --   Field = "[Field]",
          --   Variable = "[Variable]",
          --   Class = "[Class]",
          --   Interface = "[Interface]",
          --   Module = "[Module]",
          --   Property = "[Property]",
          --   Unit = "[Unit]",
          --   Value = "[Value]",
          --   Enum = "[Enum]",
          --   Keyword = "[Keyword]",
          --   Snippet = "[Snippet]",
          --   Color = "[Color]",
          --   Reference = "[Reference]",
          --   File = "[File]",
          --   Folder = "[Folder]",
          --   EnumMember = "[EnumMember]",
          --   Constant = "[Constant]",
          --   Struct = "[Struct]",
          --   Event = "[Event]",
          --   Operator = "[Operator]",
          --   TypeParameter = "[TypeParameter]",
          -- },
        }
      }
    }
  }

})
