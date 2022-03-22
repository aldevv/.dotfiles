
M = {}
local opts = {
    prompt = "Expr: ",
    default = ""
}

local on_confirm = function(expr)
    if expr == nil then
        return
    end
    require("dapui").eval(expr)
end

function M.eval()
    vim.ui.input(opts, on_confirm)
end

return M
