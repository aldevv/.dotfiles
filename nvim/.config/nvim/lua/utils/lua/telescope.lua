local M = {}
local t = require("telescope.builtin")
local a = require("telescope.actions")
local s = require("telescope.actions.state")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local themes = require("telescope.themes")
local conf = require("telescope.config").values
-- pickers creation guide
-- https://github.com/nvim-telescope/telescope.nvim/blob/master/developers.md#guide-to-your-first-picker

-- @finder is just a lua table
-- pickers.new(opts, {
--     prompt_title = "Find Files",
--     finder = finders.new_oneshot_job(find_command, opts),
--     previewer = conf.file_previewer(opts),
--     sorter = conf.file_sorter(opts),
--   }):find()

local function set_bg(path)
    vim.fn.system("changeWallpaperKeepBorders " .. path)
end

M.select_bg = function()
    t.find_files({
        prompt_title = "<BG>",
        cwd = "~/Pictures/Wallpapers",
        attach_mappings = function(prompt_bufnr, map)
            local function set_the_background(close)
                local content = s.get_selected_entry()
                set_bg(content.cwd .. "/" .. content.value)
                if close then
                    a.close(prompt_bufnr)
                end
            end

            map("i", "<C-b>", function()
                set_the_background()
            end)

            map("i", "<CR>", function()
                set_the_background(true)
            end)
            -- allow default maps like moving selection
            return true
        end,
    })
end

M.git_files_or_cwd = function()
    local opts = {}
    local ok = pcall(t.git_files, opts)
    opts = {
        prompt_title = "<PARENT DIR>",
        cwd = ".",
    }
    if not ok then
        t.find_files(opts)
    end
end

-- picker, entry maker can edit the format of the input
M.zenmode = function(opts)
    opts = opts or {}

    pickers.new(themes.get_dropdown(opts), {
        prompt_title = "<ZEN MODE>",
        finder = finders.new_table({
            results = { "TZAtaraxis", "TZMinimalist", "TZFocus" },
        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            a.select_default:replace(function()
                a.close(prompt_bufnr) -- close prompt because you pressed <cr>
                local content = s.get_selected_entry()
                vim.api.nvim_command(content.value)
            end)
            return true
        end,
    }):find()
end

-- folders
M.dotfiles = function()
    t.find_files({
        prompt_title = "<AL's DOTFILES>",
        cwd = "$XDG_CONFIG_HOME/",
    })
end

M.nvim = function(opts)
    opts = opts or { path = "" }
    t.find_files({
        prompt_title = "<AL's NVIM>",
        cwd = "$XDG_CONFIG_HOME/nvim/" .. opts.path,
    })
end

M.scripts = function()
    t.find_files({
        prompt_title = "<AL's SCRIPTS>",
        cwd = "$SCRIPTS/",
    })
end

M.files = function()
    t.find_files({
        prompt_title = "<AL's FILES>",
        cwd = "$FILES/",
    })
end

M.utilities = function()
    t.find_files({
        prompt_title = "<AL's UTILITIES>",
        cwd = "$UTILITIES/",
    })
end

M.main = function()
    t.find_files({
        prompt_title = "<AL's MAIN>",
        cwd = "$MAIN/",
    })
end

M.micro = function()
    t.find_files({
        prompt_title = "<AL's MICRO>",
        cwd = "$MICRO/",
    })
end

M.classes = function()
    t.find_files({
        prompt_title = "<AL's CLASSES>",
        cwd = "$CLASSES/",
    })
end

M.learn = function()
    t.find_files({
        prompt_title = "<AL's LEARN>",
        cwd = "$LEARN/",
    })
end

M.playground = function()
    t.find_files({
        prompt_title = "<AL's PLAYGROUND>",
        cwd = "$PLAYGROUND/",
    })
end

M.plugins_def = function()
    t.find_files({
        prompt_title = "<AL's PLUGINS>",
        cwd = "$HOME/.local/share/nvim/site/pack/",
    })
end

M.exploits = function()
    t.find_files({
        prompt_title = "<AL's EXPLOITS>",
        cwd = "$EXP/",
    })
end

return M
