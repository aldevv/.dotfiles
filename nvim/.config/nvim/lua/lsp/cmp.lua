-- =========
-- LSPKIND
-- ========
local lspkind = require("lspkind")
lspkind.init({
    -- preset: 'default' or  'codicons'
    -- preset = "default",
    -- with_text = true,
    mode = "symbol_text",
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
local luasnip = require("luasnip")

vim.api.nvim_set_option("completeopt", "menu,menuone,noselect")

cmp.setup({
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    -- NOTE: ultisnips does not work well with lsp_signature and cmp_lsp capabilities
    -- snippet = {
    --     expand = function(args)
    --         -- require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
    --         vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
    --     end,
    -- },
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
                    ultisnips = "🔥",
                    -- spell = "暈",
                    spell = "暈",
                    cmdline = "[CMD]",
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
        ["<s-up>"] = cmp.mapping(cmp.mapping.scroll_docs( -4), { "i", "c" }),
        ["<s-down>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
        ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
        ["<C-y>"] = cmp.mapping({
            i = cmp.mapping.abort(),
            c = cmp.mapping.close(),
        }),
        ["<CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace, -->https://github.com/hrsh7th/nvim-cmp/issues/664
            -- behavior = cmp.ConfirmBehavio.Replace, -->https://github.com/hrsh7th/nvim-cmp/issues/664
            --  check for examples https://github.com/hrsh7th/nvim-cmp/wiki/Example-mappings
            select = false, -- auto select on enter (even if not selected with <a-n>)
        }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    },
    -- nvim-cmp by defaults disables autocomplete for prompt buffers
    enabled = function()
        return vim.api.nvim_buf_get_option(0, "buftype") ~= "prompt" or require("cmp_dap").is_dap_buffer()
    end,
    sources = {
        -- { name = "nvim_lua" },
        { name = "nvim_lsp" },
        { name = "luasnip" }, -- For ultisnips users.
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
cmp.setup.cmdline(":", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
        { name = "path" },
    }, {
        {
            name = "cmdline",
            option = {
                ignore_cmds = { "Man", "!" },
            },
        },
    }),
})

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
