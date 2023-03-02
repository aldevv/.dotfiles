local ls = require("luasnip")
local types = require("luasnip.util.types")

ls.config.setup({
    -- This tells LuaSnip to remember to keep around the last snippet.
    -- You can jump back into it even if you move outside of the selection
    history = true,
    -- This one is cool cause if you have dynamic snippets, it updates as you type!
    updateevents = "TextChanged,TextChangedI",
    -- Autosnippets:
    enable_autosnippets = true,
    -- Crazy highlights!!
    -- #vid3
    -- ext_opts = nil,
    ext_opts = {
        [types.choiceNode] = {
            active = {
                virt_text = { { " « ", "NonTest" } },
            },
        },
    },
})

-- keymaps
vim.keymap.set({ "i", "s" }, "<a-k>", function()
    if ls.expand_or_jumpable() then
        ls.expand_or_jump()
    end
end, { silent = true })

vim.keymap.set({ "i", "s" }, "<a-s-k>", function()
    if ls.jumpable( -1) then
        ls.jump( -1)
    end
end, { silent = true })

vim.keymap.set({ "i", "s" }, "<a-l>", function()
    if ls.choice_active() then
        ls.change_choice(1)
    end
end)

-- local s = ls.snippet
-- local i = ls.insert_node
-- local t = ls.text_node
-- ls.add_snippets("all", {
--     s("my_ternary", {
--         -- equivalent to "${1:cond} ? ${2:then} : ${3:else}"
--         i(1, "cond"),
--         t(" ? "),
--         i(2, "then"),
--         t(" : "),
--         i(3, "else"),
--     }),
-- })

require("luasnip.loaders.from_lua").lazy_load({ paths = "./my_snippets/luasnip" })
require("luasnip.loaders.from_vscode").lazy_load({ paths = "./my_snippets/vscode" })
