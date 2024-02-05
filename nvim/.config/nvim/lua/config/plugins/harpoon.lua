local harpoon = require("harpoon")
local extensions = require("harpoon.extensions")

local cfg = {
	settings = {
		save_on_toggle = true,
		sync_on_ui_close = false,
		-- key = function()
		--     local obj = vim.system({ "git", "config", "--get", "remote.origin.url" }, { text = true }):wait()
		--
		--     -- if not branch, do cwd
		--     if obj.code == 1 then
		--         return vim.loop.cwd()
		--     end
		--
		--     local one_list_per_project = true
		--     if one_list_per_project then
		--         return obj.stdout
		--     end
		--
		--     -- one list per branch
		--     return vim.fn.system "git rev-parse --abbrev-ref HEAD"
		-- end,

		key = function()
			-- only works in nightly
			-- local obj = vim.system({ "git", "config", "--get", "remote.origin.url" }, { text = true }):wait()
			local out = vim.fn.system({ "git", "config", "--get", "remote.origin.url" })

			-- if not branch, do cwd
			if out == "" then
				return vim.loop.cwd()
			end

			local one_list_per_project = true
			if one_list_per_project then
				return out
			end

			-- one list per branch
			return vim.fn.system("git rev-parse --abbrev-ref HEAD")
		end,
	},
}
cfg = vim.tbl_extend("keep", cfg, require("config.plugins.harpoon_lists"))
local ok, work = pcall(require, "work")
if ok then
	local projects = {}
	projects = work.harpoon_projects
	cfg = vim.tbl_extend("keep", cfg, projects)
end

harpoon:setup(cfg)

-- runs a vim command
-- harpoon:extend(extensions.builtins.command_on_nav('echo "hi"'));

-- extension to add keybindings for the harpoon menu
harpoon:extend({
	UI_CREATE = function(cx)
		vim.keymap.set("n", "<C-v>", function()
			harpoon.ui:select_menu_item({ vsplit = true })
		end, { buffer = cx.bufnr })

		vim.keymap.set("n", "<C-x>", function()
			harpoon.ui:select_menu_item({ split = true })
		end, { buffer = cx.bufnr })

		vim.keymap.set("n", "<C-t>", function()
			harpoon.ui:select_menu_item({ tabedit = true })
		end, { buffer = cx.bufnr })
	end,
	-- same as command_on_nav
	-- NAVIGATE = function()
	--     vim.cmd(cmd)
	-- end,
})
