local M = {}


M.file_exists = function(opts)
    -- depends on the cwd
    local opts = opts or {}
    local file = require("plenary.scandir").scan_dir(vim.fn.getcwd(), { search_pattern = opts.file, depth = 1, hidden = true})
    print(next(file))
    if next(file) == nil then -- == {} doesn't work
        return false
    else
        return true
    end
end

M.is_repo_lsp = function()
    return require('lspconfig.util').find_git_ancestor(vim.fn.getcwd()) ~= nil
end

M.is_repo = function()
    if vim.regex('^fatal:'):match_str(vim.fn.system('git status')) then
        return false
    else
        return true
    end
end

-- you could use vim.fn["git#find_current_root"]()
M.find_current_root = function()
    -- TODO use lspconfig.util, it has git detection
    -- TODO check if is ok to be commented
    -- if arg[0] ~= 1 then
    --     vim.api.nvim_exec(":lcd %:p:h")
    -- end



    if M.is_repo() then
        print("first")
        return vim.fn.expand('%:p:h')
    else
        print("second")
        return vim.fn.system("git rev-parse --show-toplevel 2> /dev/null")
    end
end
return M
