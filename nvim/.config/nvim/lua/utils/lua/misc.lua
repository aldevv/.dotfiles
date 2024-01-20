local M = {}

M.date = function()
    -- 0 is the current window, returns (row, col), 2 is the col
    local pos = vim.api.nvim_win_get_cursor(0)[2]
    local line = vim.api.nvim_get_current_line()
    -- sub is to create a slice from a, to b
    -- if only given b then shows from b to the end
    local nline = line:sub(0, pos) .. "# " .. os.date "%d-%m-%y" .. line:sub(pos + 1)
    vim.api.nvim_set_current_line(nline)
    vim.api.nvim_feedkeys("o", "n", true)
end

function M.replace_termcodes(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
end

function M.visual()
    local vstart = vim.fn.getpos "'<"
    local vend = vim.fn.getpos "'>"
    local line_start = vstart[2]
    local line_end = vend[2]
    -- or use api.nvim_buf_get_lines
    return vim.fn.getline(line_start, line_end)
end

return M
