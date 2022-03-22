require("lsp_signature").setup({
    floating_window_above_cur_line = true, -- try to place the floating above the current line when possible Note:
    -- will set to true when fully tested, set to false will use whichever side has more space
    -- this setting will be helpful if you do not want the PUM and floating win overlap
    bind = true, -- This is mandatory, otherwise border config won't get registered.
    floating_window = false, -- show hint in a floating window, set to false for virtual text only mode
    hint_enable = true, -- virtual hint enable
    hi_parameter = "LspSignatureActiveParameter", -- how your parameter will be highlight
    extra_trigger_chars = { "(", "," },
    hint_prefix = "🐼 ", -- Panda for parameter
    toggle_key = "<M-->",
    transparency = nil,
    handler_opts = {
        border = "rounded",
    },
})
