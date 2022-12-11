local M = {}

M.date = function()
    -- 0 is the current window, returns (row, col), 2 is the col
    local pos = vim.api.nvim_win_get_cursor(0)[2]
    local line = vim.api.nvim_get_current_line()
    -- sub is to create a slice from a, to b
    -- if only given b then shows from b to the end
    local nline = line:sub(0, pos) .. "# " .. os.date("%d-%m-%y") .. line:sub(pos + 1)
    vim.api.nvim_set_current_line(nline)
    vim.api.nvim_feedkeys("o", "n", true)
end

-- TODO: load a yaml file that saves project level files to float (like harpoon)
M.toggle_float_file = function(file)
    require("utils.lua.float").float_file(file)
end

M.testing = function()
    print("this is for fun stuff")
end

return M
