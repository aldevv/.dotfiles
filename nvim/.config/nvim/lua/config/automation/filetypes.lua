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
		-- -- NOTE: by neovim 9.2 this should work without this var and the pattern
		-- local ft = vim.bo.ft
		vim.api.nvim_create_autocmd({ "VimEnter" }, {
			-- pattern = "*." .. ft,
			callback = function()
				-- if buffer is empty
				if vim.fn.line("$") ~= 1 or vim.fn.getline(1) ~= "" then
					return
				end
				local snips = require("luasnip").get_snippets()[vim.bo.ft]
				if snips == nil then
					return true
				end
				for _, snip in ipairs(snips) do
					if snip["name"] == "_skel" then
						require("luasnip").snip_expand(snip)

						vim.api.nvim_input("<esc>")
						return true
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

-- for bug where cmp doesn't close on win enter
vim.api.nvim_create_autocmd("CmdWinEnter", {
	callback = function()
		require("cmp").close()
	end,
})
