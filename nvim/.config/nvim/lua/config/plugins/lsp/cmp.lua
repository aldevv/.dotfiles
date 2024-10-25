-- =========
-- LSPKIND
-- ========

local lspkind_comparator = function(conf)
  local lsp_types = require("cmp.types").lsp
  return function(entry1, entry2)
    if entry1.source.name ~= "nvim_lsp" then
      if entry2.source.name == "nvim_lsp" then
        return false
      else
        return nil
      end
    end
    local kind1 = lsp_types.CompletionItemKind[entry1:get_kind()]
    local kind2 = lsp_types.CompletionItemKind[entry2:get_kind()]
    if kind1 == "Variable" and entry1:get_completion_item().label:match("%w*=") then
      kind1 = "Parameter"
    end
    if kind2 == "Variable" and entry2:get_completion_item().label:match("%w*=") then
      kind2 = "Parameter"
    end

    local priority1 = conf.kind_priority[kind1] or 0
    local priority2 = conf.kind_priority[kind2] or 0
    if priority1 == priority2 then
      return nil
    end
    return priority2 < priority1
  end
end

local label_comparator = function(entry1, entry2)
  return entry1.completion_item.label < entry2.completion_item.label
end

local lspkind = require("lspkind")
lspkind.init({
  -- preset: 'default' or  'codicons'
  -- preset = "default",
  -- with_text = true,
  mode = "symbol_text",
  symbol_map = {
    Text = "󰉿",
    Method = "󰆧",
    Function = "󰊕",
    Constructor = "",
    Field = "󰜢",
    Variable = "󰀫",
    Class = "󰠱",
    Interface = "",
    Module = "",
    Property = "󰜢",
    Unit = "󰑭",
    Value = "󰎠",
    Enum = "",
    Keyword = "󰌋",
    Snippet = "",
    Color = "󰏘",
    File = "󰈙",
    Reference = "󰈇",
    Folder = "󰉋",
    EnumMember = "",
    Constant = "󰏿",
    Struct = "󰙅",
    Event = "",
    Operator = "󰆕",
    TypeParameter = "🔥",
  },
})

-- ==========
-- COMPLETION
-- ==========
local cmp = require("cmp")
local luasnip = require("luasnip")

vim.api.nvim_set_option_value("completeopt", "menu,menuone,noselect", {})

cmp.setup({
  preselect = cmp.PreselectMode.None, -- so it doesn't select lsp automatically, and lets me choose manually
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  formatting = {

    format = function(entry, vim_item)
      vim_item.kind = string.format("%s %s", lspkind.presets.default[vim_item.kind], vim_item.kind)
      vim_item.menu = ({
        -- nvim_lsp = "ﲳ",
        -- nvim_lsp = "📚",
        luasnip = "🔥",
        -- nvim_lua = "[nvim]",
        nvim_lsp = "[LS]",
        -- nvim_lua = "[API]",
        -- treesitter = "",
        treesitter = "🌲",
        -- path = "ﱮ",
        path = "📁",
        -- buffer = "﬘",
        buffer = "[BUF]",
        zsh = "[SH]",
        -- vsnip = "",
        -- ultisnips = "🔥",
        -- spell = "暈",
        spell = "暈",
        cmdline = "[CMD]",
        cody = "[CODY]",
        ["vim-dadbod-completion"] = "[DB]",
      })[entry.source.name]

      return vim_item
    end,
  },
  experimental = {
    ghost_text = true,
    -- native_menu = true
  },
  mapping = {
    -- Manually trigger cody completions
    ["<c-a>"] = cmp.mapping.complete({
      config = {
        sources = {
          { name = "cody" },
        },
      },
    }),
    ["<a-e>"] = cmp.mapping(cmp.mapping.select_prev_item(), { "i", "c" }),
    ["<a-n>"] = cmp.mapping(cmp.mapping.select_next_item(), { "i", "c" }),
    ["<a-u>"] = function(fallback)
      if cmp.visible() then
        for _ = 1, 2 do
          cmp.select_prev_item()
        end
      else
        fallback()
      end
    end,
    ["<a-d>"] = function(fallback)
      if cmp.visible() then
        for _ = 1, 2 do
          cmp.select_next_item()
        end
      else
        fallback()
      end
    end,
    ["<a-S-e>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
    ["<a-S-n>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
    ["<C-Space>"] = cmp.mapping(function()
      if cmp.visible() then
        cmp.close()
      else
        cmp.complete()
      end
    end, { "i", "c" }),
    ["<CR>"] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Replace, -->https://github.com/hrsh7th/nvim-cmp/issues/664
      -- behavior = cmp.ConfirmBehavior.Insert, -->https://github.com/hrsh7th/nvim-cmp/issues/664
      -- behavior = cmp.ConfirmBehavior.Replace, -->https://github.com/hrsh7th/nvim-cmp/issues/664
      --  check for examples https://github.com/hrsh7th/nvim-cmp/wiki/Example-mappings
      -- select = true, -- auto select on enter (even if not selected with <a-n>)
      select = true, -- auto select on enter (even if not selected with <a-n>)
    }),              -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    -- same as <cr> but it auto selects first option
    -- ["<a-y>"] = cmp.mapping.confirm({
    --   behavior = cmp.ConfirmBehavior.Insert,
    --   select = true, -- auto select on enter (even if not selected with <a-n>)
    -- }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  },
  -- nvim-cmp by defaults disables autocomplete for prompt buffers
  -- enabled = function()
  --   return vim.api.nvim_get_option_value("buftype", { buf = 0 }) ~= "prompt" or require("cmp_dap").is_dap_buffer()
  -- end,
  sorting = {
    -- TODO: Would be cool to add stuff like "See variable names before method names" in rust, or something like that.
    comparators = {
      cmp.config.compare.score,
      cmp.config.compare.sort_text,
      lspkind_comparator({
        kind_priority = {
          Parameter = 14,
          Variable = 12,
          Field = 11,
          Property = 11,
          Constant = 10,
          Enum = 10,
          EnumMember = 10,
          Event = 10,
          Function = 10,
          Method = 10,
          Operator = 10,
          Reference = 10,
          Struct = 10,
          File = 8,
          Folder = 8,
          Class = 5,
          Color = 5,
          Module = 5,
          Keyword = 2,
          Constructor = 1,
          Interface = 1,
          Snippet = 0,
          Text = 1,
          TypeParameter = 1,
          Unit = 1,
          Value = 1,
        },
      }),
      label_comparator,
    }
  },
  sources = {
    { name = "luasnip",              priority = 1 },
    -- { name = "nvim_lua" },
    { name = "nvim_lsp",             priority = 2 },
    -- { name = "ultisnips" }, -- For ultisnips users.
    -- these below also need a plugin like cmp-nvim-ultisnips
    { name = "path",                 max_item_count = 10 },
    -- { name = 'luasnip' }, TODO change to this!
    { name = "buffer",               keyword_length = 5 },
    { name = "dap" },
    { name = "orgmode" },
    { name = "vim-dadbod-completion" },
    { name = "git" },
    -- { name = 'snippy' }, -- For snippy users.
    -- { name = 'treesitter' },
  },
})

-- command line
-- NOTE: has bug with %, where it doesn't complete it correctly
cmp.setup.cmdline(":", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    --   { name = "path", option = {
    --     ignore_cmds = { "Man", "!" },
    --   } },

    {
      name = "cmdline",
      option = {
        ignore_cmds = { "Man", "!" },
      },
    },
  }),
})

-- cmp.setup.cmdline(":", {
--   sources = cmp.config.sources({
--
--     {
--       name = "cmdline",
--       option = {
--         ignore_cmds = { "Man", "!", "edit", "read" },
--       },
--     },
--     {
--       name = "fuzzy_path",
--       option = {
--         fd_cmd = { "fd", "-d", "20", "-p" },
--       },
--     },
--   }),
-- })

-- / search
cmp.setup.cmdline("/", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = "buffer" },
  },
})

require("cmp_git").setup({
  filetypes = { "gitcommit", "octo" },
  remotes = { "origin", "upstream" },
})
-- Set configuration for specific filetype.
cmp.setup.filetype("gitcommit", {
  sources = cmp.config.sources({
    { name = "git" }, -- You can specify the `git` source if [you were installed it](https://github.com/petertriho/cmp-git).
  }, {
    { name = "buffer" },
  }),
})

cmp.setup.filetype("harpoon", {
  sources = cmp.config.sources({
    { name = "path" },
    -- { name = 'fuzzy_path' }, -- You can specify the `git` source if [you were installed it](https://github.com/petertriho/cmp-git).
  }),
})
