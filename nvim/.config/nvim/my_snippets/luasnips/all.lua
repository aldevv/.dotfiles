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

return {
	parse("nope", "local $1 = function($2)\n yup $0\nend"),
}
