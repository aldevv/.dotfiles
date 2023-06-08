-- local s = ls.snippet
-- local i = ls.insert_node
-- local t = ls.text_node
-- ================================

-- https://github.com/L3MON4D3/LuaSnip/blob/master/lua/luasnip/config.lua#L122-L147
-- https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md#loaders
-- local ls = require("luasnip")
-- local t = require("luasnip").text_node -- fails if not imported
-- local s = ls.snippet
-- local sn = ls.snippet_node
-- 	local isn = require("luasnip.nodes.snippet").ISN
-- local t = ls.text_node
-- local i = ls.insert_node
-- local f = ls.function_node
-- local c = ls.choice_node
-- local d = ls.dynamic_node
-- local r = require("luasnip.extras").rep
-- local l = require("luasnip.extras").lambda
-- local dl = require("luasnip.extras").dynamic_lambda
-- 	local ai = require("luasnip.nodes.absolute_indexer")
-- local p = require("luasnip.extras").partial
-- local m = require("luasnip.extras").match
-- local n = require("luasnip.extras").nonempty
-- local fmt = require("luasnip.extras.fmt").fmt
-- local fmta = require("luasnip.extras.fmt").fmta
-- local types = require("luasnip.util.types")
-- local conds = require("luasnip.extras.expand_conditions")
-- local isn = ls.indent_snippet_node
-- local events = require("luasnip.util.events")
-- 	local extras = require("luasnip.extras")
-- 	local rep = require("luasnip.extras").rep
-- 	local postfix = require("luasnip.extras.postfix").postfix
-- 	local parse = require("luasnip.util.parser").parse_snippet
-- 	local ms = require("luasnip.nodes.multiSnippet").new_multisnippet

local ls = require("luasnip")
local types = require("luasnip.util.types")

ls.config.setup({
	-- snip_env =
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
vim.keymap.set({ "i", "s" }, "<a-l>", function()
	if ls.expand_or_jumpable() then
		ls.expand_or_jump()
	end
end, { silent = true })

vim.keymap.set({ "i", "s" }, "<a-k>", function()
	if ls.jumpable(1) then
		ls.jump(1)
	end
end, { silent = true })

vim.keymap.set({ "i", "s" }, "<a-s-k>", function()
	if ls.jumpable(-1) then
		ls.jump(-1)
	end
end, { silent = true })

vim.keymap.set({ "i", "s" }, "<a-s-l>", function()
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

-- https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md#loaders
-- https://www.ejmastnak.com/tutorials/vim-latex/luasnip/#files
-- https://www.ejmastnak.com/tutorials/vim-latex/luasnip/#loading
require("luasnip.loaders.from_lua").lazy_load({ paths = "~/.dotfiles/nvim/.config/nvim/my_snippets/luasnips" })
require("luasnip.loaders.from_vscode").lazy_load({ paths = "./my_snippets/vscode" })
