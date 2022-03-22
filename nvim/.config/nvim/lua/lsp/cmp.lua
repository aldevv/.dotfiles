-- =========
-- LSPKIND
-- ========
local lspkind = require("lspkind")
lspkind.init({
    -- preset: 'default' or  'codicons'
    -- preset = "default",
    -- with_text = true,
    mode = 'symbol_text',
    symbol_map = {
        Text = "",
        Method = "ƒ",
        Function = "ﬦ",
        Constructor = "",
        Variable = "",
        Class = "",
        Interface = "ﰮ",
        Module = "",
        Property = "",
        Unit = "",
        Value = "",
        Enum = "了",
        Keyword = "",
        Snippet = "﬌",
        Color = "",
        File = "",
        Folder = "",
        EnumMember = "",
        Constant = "",
        Struct = "",
    },
})

-- ==========
-- COMPLETION
-- ==========
local cmp = require("cmp")
vim.api.nvim_set_option("completeopt", "menu,menuone,noselect")

cmp.setup({
    snippet = {
        expand = function(args)
            -- require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
            vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
        end,
    },

    formatting = {
        format = function(entry, vim_item)
            vim_item.kind = string.format("%s %s", lspkind.presets.default[vim_item.kind], vim_item.kind)
            vim_item.menu = ({
                -- nvim_lsp = "ﲳ",
                -- nvim_lsp = "📚",
                nvim_lsp = "[LS]",
                nvim_lua = "[api]",
                -- treesitter = "",
                treesitter = "🌲",
                -- path = "ﱮ",
                path = "📁",
                -- buffer = "﬘",
                buffer = "[buf]",
                zsh = "[sh]",
                -- vsnip = "",
                ultisnips = "🔥",
                -- spell = "暈",
                spell = "暈",
            })[entry.source.name]

            return vim_item
        end,
    },
    experimental = {
        ghost_text = true,
        -- native_menu = true
    },
    mapping = {
        -- snippets
        -- ["<a-t>"] = cmp.mapping(function(fallback)
        --     if require("luasnip").expand_or_jumpable() then
        --         require("luasnip").expand_or_jump()
        --     else
        --         fallback()
        --     end
        -- end, { "i", "s" }),
        -- ["<a-s>"] = cmp.mapping(function(fallback)
        --     if require("luasnip").jumpable(-1) then
        --         require("luasnip").jump(-1)
        --     else
        --         fallback()
        --     end
        -- end, { "i", "s" }),

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
        -- these are for the popup docs, TODO change to the ones in coc
        ["<C-e>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
        ["<C-n>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
        ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
        ["<C-y>"] = cmp.mapping({
            i = cmp.mapping.abort(),
            c = cmp.mapping.close(),
        }),
        ["<CR>"] = cmp.mapping.confirm({
            cmp.ConfirmBehavior.Insert, -->https://github.com/hrsh7th/nvim-cmp/issues/664
            --  check for examples https://github.com/hrsh7th/nvim-cmp/wiki/Example-mappings
            select = false, -- auto select on enter (even if not selected with <a-n>)
        }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    },
    sources = {
        { name = "nvim_lua" },
        { name = "nvim_lsp" },
        -- { name = "luasnip" },
        { name = "ultisnips" }, -- For ultisnips users.
        -- these below also need a plugin like cmp-nvim-ultisnips
        { name = "path", max_item_count = 10 },
        -- { name = 'luasnip' }, TODO change to this!
        { name = "buffer", keyword_length = 5 },
        -- { name = 'snippy' }, -- For snippy users.
        -- { name = 'treesitter' },
    },
})

-- If you want insert `(` after select function or method item
