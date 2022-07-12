require("refactoring").setup({
	prompt_func_return_type = {
		go = false,
		java = false,

		cpp = false,
		c = false,
		h = false,
		hpp = false,
		cxx = false,
	},
	prompt_func_param_type = {
		go = false,
		java = false,

		cpp = false,
		c = false,
		h = false,
		hpp = false,
		cxx = false,
	},
	printf_statements = {
		-- add a custom printf statement for cpp
		cpp = {
			'std::cout << "%s" << std::endl;',
		},
	},
	print_var_statements = {},
})

-- load refactoring Telescope extension
require("telescope").load_extension("refactoring")
