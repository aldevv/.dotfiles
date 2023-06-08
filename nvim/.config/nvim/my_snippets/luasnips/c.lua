return {
	s("all_fn", {
		-- Simple static text.
		t("//Parameters: "),
		-- function, first parameter is the function, second the Placeholders
		-- whose text it gets as input.
		t({ "", "function " }),
		-- Placeholder/Insert.
		i(1),
		t("("),
		-- Placeholder with initial text.
		i(2, "int foo"),
		-- Linebreak
		t({ ") {", "\t" }),
		-- Last Placeholder, exit Point of the snippet. EVERY 'outer' SNIPPET NEEDS Placeholder 0.
		i(0),
		t({ "", "}" }),
	}),
	s("keyword", { t("text") }),
	s("_skel", {
		t({ "#include <stdio.h>", "", "" }),
		t({ "int main(int argc, char *argv[])", "{", "\t" }),
		i(1),
		t({ "", "\treturn 0;", "" }),
		i(2),
		t({ "}" }),
	}),
}
