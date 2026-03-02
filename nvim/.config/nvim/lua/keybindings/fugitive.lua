-- " =====================
-- " Sweet Sweet FuGITive
-- " =====================
-- " vimdiff commnads
-- ""]c :        - next difference
-- "[c :        - previous difference
-- "do          - diff obtain
-- "dp          - diff put
-- "zo          - open folded text
-- "zc          - close folded text
-- ":diffupdate - re-scan the files for differences
-- " default diffopt
-- " set diffopt=internal,filler,closeoff

local s = { silent = true }
local nor = { noremap = true }
local e = { expr = true }
local s_e = vim.tbl_extend("keep", s, e)

local nor_s = vim.tbl_extend("keep", nor, s)
local nor_e = vim.tbl_extend("keep", nor, e)
local nor_e_s = vim.tbl_extend("keep", nor, e, s)

local desc = function(desc)
	return vim.tbl_extend("keep", nor_s, { desc = desc })
end

local descv = function(desc)
	return vim.tbl_extend("keep", nor, { desc = desc })
end

local map = vim.keymap.set

-- use d2o and d3o
map("n", "<leader>g ", ":G ", nor)
map("v", "<leader>gdi", ":diffget //3<CR>", nor)
map("v", "<leader>gdh", ":diffget //2<CR>", nor)

map("n", "<leader>gd<space>", ":Gvdiffsplit @~", descv("Gdiffsplit @~_"))
map("n", "<leader>gdd", ":Gvdiffsplit @~<cr>", descv("Gdiffsplit @~"))
map("n", "<leader>gdD", ":Gsplit @~", nor)
map("n", "<leader>gdq", ":G difftool @~", descv("Gdiffsplit @~_"))

map("n", "gs", ":G<CR>", nor)
map("n", "<leader>gsta", ":G stash<CR>", nor)
map("n", "<leader>gstA", ":G stash apply<CR>", nor)
map("n", "<leader>gst", ":Telescope git_stash<CR>", nor)
-- map("n", "<leader>gSs", ":G stash<CR>", nor)
-- map("n", "<leader>gSp", ":G stash pop<CR>", nor)

map("n", "<leader>gi", ":G init<CR>", nor)
map("n", "<leader>gm", ":G mergetool<CR>", nor)

-- for this file
map("n", "<leader>0", ":0Gclog<cr>", descv("git log current file <0Gclog>"))
map("n", "<leader>gv", ":GV<cr>", descv("GV"))
map("n", "<leader>gV", ":GV!<CR>", nor) -- only list commits current file

map("n", "<leader>g0<space>", ":0Gclog ", descv("git log current file <0Gclog>"))
map("n", "<leader>g0g", ":0Gclog<cr>", nor)
map("n", "<leader>g0G", ":G log --decorate=short --all %<cr>", nor)
map("n", "<leader>g0m", ":0Gclog! ", nor)
map("n", "<leader>g0M", ":G! log % ", nor)

-- old way
map("n", "g0", ":0Gclog!<cr>", nor)
map("n", "<leader>gl0<space>", ":0Gclog ", descv("git log current file <0Gclog>"))
map("n", "<leader>gl0g", ":0Gclog!<cr>", nor)
map("n", "<leader>gl0G", ":G log --decorate=short --all %<cr>", nor)
map("n", "<leader>gl0m", ":0Gclog! ", nor)
map("n", "<leader>gl0M", ":G! log % ", nor)
map("n", "<leader>gl0v", ":GV!<CR>", nor) -- only list commits current file

map("n", "gC", ":G commit<CR>", nor) -- only list commits current file

-- while in the git log you can do:
-- coo to checkout that commit!
-- O to open in new tab
-- o to open in split
-- p to preview
-- <cr> to enter commit
map("n", "<leader>glt", ":Telescope git_commits<CR>", descv("Telescope git log <Telescope git_commits>"))
map("n", "<leader>glg", ":G log --decorate=short<CR>", descv("G log <normal>"))
map("n", "<leader>glm", ":G log ", descv("G log _")) -- you could do % to view log of file
map("n", "<leader>gl<space>", ":G log ", descv("G log _")) -- you could do % to view log of file

map("n", "<leader>glG", ":Gclog!<CR>", descv("Gclog <quickfix>"))
map("v", "<leader>glg", ":Gclog!<CR>", nor) -- works in visual mode

map("n", "<leader>gla", ":G log --decorate=short --all<CR>", nor)
map("n", "<leader>glo", ":G log --oneline --all<CR>", nor)

map("n", "<leader>glM", ":Gclog! ", descv("Gclog! _"))
map("v", "<leader>glm", ":Gclog! ", nor)
map("v", "<leader>gl<space>", ":Gclog! ", descv("Gclog! _"))

map("n", "<leader>gp", ":G push -u origin HEAD<cr>", descv("G push -u origin HEAD"))
map(
	"n",
	"<leader>gP",
	":G push --force-with-lease --force-if-includes<cr>",
	descv("G push --force-with-lease --force-if-includes")
)
map("n", "<leader>gL", ":G pull<CR>", desc("G pull"))

map("n", "<leader>gb", ":G blame<CR>", nor)
map("n", "<leader>gB", ":GBrowse<CR>", nor)
map("n", "<leader>ga", ":GWrite<CR>", nor)
map("n", "<leader>gcc", ":G! commit<CR>", descv("G! commit"))
map("n", "<leader>gc<space>", ":G! commit ", descv("G! commit _"))
map("n", "<leader>gco", ":Telescope git_branches<CR>", descv("Telescope git_branches"))
map("n", "<leader>gcO", ":G! checkout -<CR>", descv("git checkout previous<G checkout ->"))
map("n", "<leader>gr", ":Gread<CR>", nor) -- use index
map("n", "<leader>gR", ":Gread -<CR>", nor) -- use commit
map("n", "<leader>gw", ":Gwrite<CR>", nor)
map("n", "<leader>ge", ":Gedit<CR>", nor)
map("n", "<leader>gS", ":Gsplit @~", nor)

-- GV
-- o or <cr> on a commit to display the content of it
-- o or <cr> on commits to display the diff in the range
-- O opens a new tab instead
-- gb for :GBrowse
-- ]] and [[ to move between commits
-- . to start command-line with :Git [CURSOR] SHA à la fugitive
-- q or gq to close
map("n", "<leader>glvv", ":GV<CR>", nor) -- other plugin to visualize repo, you can use visual mode too
map("n", "<leader>glv?", ":GV!<CR>", nor) -- location list fill
map("v", "<leader>glvv", ":GV<CR>", nor) -- other plugin to visualize repo, you can use visual mode too
map("v", "<leader>glv0", ":GV!<CR>", nor) -- only list commits current file
map("v", "<leader>glv?", ":GV!<CR>", nor) -- location list fill

map("n", "<leader>gVv", ":GV<CR>", nor) -- commit history
map("n", "<leader>gV0", ":GV!<CR>", nor) -- commit history current file
map("v", "<leader>gVv", ":GV<CR>", nor) -- other plugin to visualize repo, you can use visual mode too
map("v", "<leader>gV0", ":GV!<CR>", nor) -- only list commits current file

map("n", "<leader>gv", ":Gvsplit @~", nor)

local function git_show_qf(ref)
	local cmd = "git show --name-only --format=" .. (ref ~= "" and (" " .. ref) or "")
	local files = vim.fn.systemlist(cmd)
	local items = {}
	for _, f in ipairs(files) do
		if f ~= "" then
			table.insert(items, { filename = f, lnum = 1 })
		end
	end
	vim.fn.setqflist({}, "r", { title = "git show " .. ref, items = items })
	vim.cmd("copen")
end

map("n", "<leader>gshh", function()
	local prev = vim.api.nvim_get_current_buf()
	vim.cmd("G show")
	vim.api.nvim_buf_delete(prev, { force = true })
end, desc("G show (replace buf)"))
map("n", "<leader>gsh<space>", function()
	local ref = vim.fn.input("git show ref: ")
	if ref ~= "" then
		local prev = vim.api.nvim_get_current_buf()
		vim.cmd("G show " .. ref)
		vim.api.nvim_buf_delete(prev, { force = true })
	end
end, descv("G show <ref> (replace buf)"))

map("n", "<leader>gsH", function()
	local prev = vim.api.nvim_get_current_buf()
	vim.cmd("G show")
	vim.api.nvim_buf_delete(prev, { force = true })
end, desc("G show (replace buf)"))

map("n", "<leader>gshq", function()
	git_show_qf("")
end, vim.tbl_extend("keep", desc("git show → qf"), { nowait = true }))

map("n", "<leader>gshq<space>", function()
	local ref = vim.fn.input("git show ref: ")
	if ref ~= "" then
		git_show_qf(ref)
	end
end, descv("git show <ref> → qf"))

local function git_show_telescope(ref)
	local cmd = "git show --name-only --format=" .. (ref ~= "" and (" " .. ref) or "")
	local files = vim.fn.systemlist(cmd)
	local items = {}
	for _, f in ipairs(files) do
		if f ~= "" then
			table.insert(items, f)
		end
	end
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local previewers = require("telescope.previewers")
	local conf = require("telescope.config").values
	local show_ref = ref ~= "" and ref or "HEAD"
	pickers.new({}, {
		prompt_title = "git show " .. show_ref,
		finder = finders.new_table({ results = items }),
		sorter = conf.generic_sorter({}),
		previewer = previewers.new_termopen_previewer({
			get_command = function(entry)
				return { "git", "show", show_ref, "--", entry.value }
			end,
		}),
	}):find()
end

map("n", "<leader>gsht", function()
	git_show_telescope("")
end, vim.tbl_extend("keep", desc("git show → telescope"), { nowait = true }))

map("n", "<leader>gsht<space>", function()
	local ref = vim.fn.input("git show ref: ")
	if ref ~= "" then
		git_show_telescope(ref)
	end
end, descv("git show <ref> → telescope"))
