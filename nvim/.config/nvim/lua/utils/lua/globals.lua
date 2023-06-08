--
-- these are loaded so you can do : lua put({1,2,3})
function _G.put(...)
	local objects = {}
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		table.insert(objects, vim.inspect(v))
	end

	print(table.concat(objects, "\n"))
	return ...
end

function _G._replace_termcodes(str)
	return vim.api.nvim_replace_termcodes(str, true, true, true)
end

function _G.is_work_env()
	return vim.fn.system("cd ~/.dotfiles; git branch --show-current | tr -d '\\n'; cd -") == "work"
end
