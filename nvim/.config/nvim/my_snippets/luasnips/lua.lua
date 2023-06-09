-- parse("nope", "local $1 = function($2)\n yup $0\nend"),-- parse("nope", "local $1 = function($2)\n yup $0\nend"),
-- return {
--     parse("nope", "local $1 = function($2)\n yup $0\nend"),
-- }

-- return {
--
-- 	-- parse("my_c", "local $1 = function($2)\n yup $0\nend"),
-- 	-- -- A simple "Hello, world!" text node
-- 	s(
-- 		{ trig = "hi" }, -- Table of snippet parameters
-- 		{ -- Table of snippet nodes
-- 			t("Hello, world!"),
-- 		}
-- 	),
-- }
return {
	-- this snippet will make the var name the last part of the require
	--  local builtin = require "telescope.pickers.builtin"
	s(
		"requi",
		fmt([[local {} = require "{}"]], {
			f(function(import_name)
				local parts = vim.split(import_name[1][1], ".", true)
				return parts[#parts] or ""
			end, { 1 }),
			i(1),
		})
	),
}
