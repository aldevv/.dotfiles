require("refactoring").setup({
	prompt_func_return_type = {
		go = false, -- default
	},
	prompt_func_param_type = {
		go = false, -- default
	},
	printf_statements = {
		cpp = {
			'std::cout << "%s" << std::endl;',
		},
		-- rs = {
		--   'println!("%s")'
		-- },
	},
	print_var_statements = {
		-- %% is to escape the %
		go = {
			'fmt.Println(fmt.Sprintf("%s %%+v", %s))',
		},
		cpp = {
			'printf("a custom statement %%s %s", %s)',
		},
		-- rs = {
		--   'println!("%s {}", %s)'
		-- },
	},
})

-- load refactoring Telescope extension
local ok, telescope = pcall(require, "telescope")
if not ok then
	return
end
telescope.load_extension("refactoring")
