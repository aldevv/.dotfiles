-- local ls = require("luasnip")
-- local t = require("luasnip").text_node -- fails if not imported
-- local s = ls.snippet
-- local sn = ls.snippet_node
-- 	local isn = require("luasnip.nodes.snippet").ISN
-- local t = ls.text_node
-- local i = ls.insert_node
-- local f = ls.function_node

-- choice nodes c($1, {node1, node2})
-- local c = ls.choice_node

-- magical, it returns snippets
-- local d = ls.dynamic_node
-- local r = require("luasnip.extras").rep
-- local l = require("luasnip.extras").lambda
-- local dl = require("luasnip.extras").dynamic_lambda
-- 	local ai = require("luasnip.nodes.absolute_indexer")
-- local p = require("luasnip.extras").partial
-- local m = require("luasnip.extras").match
-- local n = require("luasnip.extras").nonempty

-- fmts a node, use {} to put input where you want
-- local fmt = require("luasnip.extras.fmt").fmt

-- local fmta = require("luasnip.extras.fmt").fmta
-- local types = require("luasnip.util.types")
-- local conds = require("luasnip.extras.expand_conditions")
-- local isn = ls.indent_snippet_node
-- local events = require("luasnip.util.events")
-- 	local extras = require("luasnip.extras")

-- repeats a node
-- 	local rep = require("luasnip.extras").rep

-- 	local postfix = require("luasnip.extras.postfix").postfix
-- 	local parse = require("luasnip.util.parser").parse_snippet
-- 	local ms = require("luasnip.nodes.multiSnippet").new_multisnippet

-- tj tutorial
-- part 1 and 2
-- https://www.youtube.com/watch?v=Dn800rlPIho&t
-- https://www.youtube.com/watch?v=KtQZRAkgLqo

return {
	parse("nope", "nooope"),
	s(
		"curtime",
		f(function()
			return os.date("%D - %H:%M")
		end)
	),
}
