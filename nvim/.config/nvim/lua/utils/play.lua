local M = {}
M.file_exists = function()
    local file = require("plenary.scandir").scan_dir(vim.fn.getcwd(), { search_pattern = ".env", depth = 1, hidden = true})
    if next(file) then -- == {} doesn't work
        return true
    else
        -- table is empty
        return false
    end
end
return M
