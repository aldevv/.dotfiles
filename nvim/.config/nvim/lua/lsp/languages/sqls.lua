local M = {}

local on_attach_deco = function(fn)
    local inner = function(client, bufnr)
        fn(client, bufnr)
        require("sqls").on_attach(client, bufnr)
        vim.keymap.set("n", "<cr>", "<cmd>SqlsExecuteQuery<cr>", { buffer = 0 })
    end
    return inner
end

M.exec = function(opts)
    opts.on_attach = on_attach_deco(opts.on_attach)
end
return M
