vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = "launch.json",
	callback = function()
		-- this combines snippets for launch specific and json filetypes
		vim.opt.filetype = "launchjson"
		vim.opt.syntax = "json"
	end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = "docker-compose.json",
	callback = function()
		-- this combines snippets for launch specific and json filetypes
		vim.opt.filetype = "docker-compose"
		vim.opt.syntax = "yaml"
	end,
})

-- autoload _skel
vim.api.nvim_create_autocmd("BufNewFile", {
	callback = function()
		vim.api.nvim_create_autocmd("BufEnter", {
			callback = function()
				-- if buffer is empty
				if vim.fn.line("$") ~= 1 or vim.fn.getline(1) ~= "" then
					return
				end
				local snips = require("luasnip").get_snippets()[vim.bo.ft]
				for _, snip in ipairs(snips) do
					if snip["name"] == "_skel" then
						vim.pretty_print(snip)
						require("luasnip").snip_expand(snip)
						return
					end
				end
			end,
		})
	end,
})

vim.api.nvim_create_autocmd({ "BufEnter" }, {
	pattern = "*Neotest Summary*",
	callback = function()
		vim.keymap.set("n", "n", "j", { silent = true, buffer = 0 })
		vim.keymap.set("n", "e", "k", { silent = true, buffer = 0 })
		-- vim.keymap.set("n", "<space>", "lua neotest.Config.summary.mappings
	end,
})
