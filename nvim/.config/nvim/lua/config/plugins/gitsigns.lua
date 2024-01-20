require("gitsigns").setup {
    signs = {
        add = { hl = "GitSignsAdd", text = "│", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
        change = { hl = "GitSignsChange", text = "│", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
        delete = { hl = "GitSignsDelete", text = "_", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
        topdelete = { hl = "GitSignsDelete", text = "‾", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
        changedelete = { hl = "GitSignsChange", text = "~", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
    },
    signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
    numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
    linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
    word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
    -- keymaps = {
    --   -- Default keymap options
    --   noremap = true,
    --
    --   ["n ]c"] = { expr = true, "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'" },
    --   ["n [c"] = { expr = true, "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'" },
    --
    --   ["n <leader>ggs"] = "<cmd>Gitsigns stage_hunk<CR>",
    --   ["v <leader>ggs"] = ":Gitsigns stage_hunk<CR>",
    --   ["n <leader>ggu"] = "<cmd>Gitsigns undo_stage_hunk<CR>",
    --   ["n <leader>ggrr"] = "<cmd>Gitsigns reset_hunk<CR>",
    --   ["v <leader>ggrr"] = ":Gitsigns reset_hunk<CR>",
    --   ["n <leader>ggrb"] = "<cmd>Gitsigns reset_buffer<CR>",
    --   ["n <leader>ggrB"] = "<cmd>Gitsigns reset_buffer_index<CR>", -- this doesn't undo changes!!
    --   ["n <leader>ggp"] = "<cmd>Gitsigns preview_hunk<CR>",
    --   ["n <leader>ggb"] = '<cmd>lua require"gitsigns".blame_line{full=true}<CR>',
    --   ["n <leader>ggS"] = "<cmd>Gitsigns stage_buffer<CR>",
    --   ["n <leader>ggq"] = "<cmd>Gitsigns setqflist<CR>",
    --   ["n <leader>ggl"] = "<cmd>Gitsigns setloclist<CR>",
    --
    --   -- Text objects
    --   ["o lh"] = ":<C-U>Gitsigns select_hunk<CR>",
    --   ["x lh"] = ":<C-U>Gitsigns select_hunk<CR>",
    -- },
    watch_gitdir = {
        interval = 1000,
        follow_files = true,
    },
    attach_to_untracked = true,
    current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
    current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
        delay = 1000,
        ignore_whitespace = false,
    },
    current_line_blame_formatter_opts = {
        relative_time = false,
    },
    sign_priority = 6,
    update_debounce = 100,
    status_formatter = nil, -- Use default
    max_file_length = 40000,
    preview_config = {
        -- Options passed to nvim_open_win
        border = "single",
        style = "minimal",
        relative = "cursor",
        row = 0,
        col = 1,
    },
    yadm = {
        enable = false,
    },
}

vim.keymap.set("n", "]c", "<cmd>Gitsigns next_hunk<CR>")
vim.keymap.set("n", "[c", "<cmd>Gitsigns prev_hunk<CR>")

vim.keymap.set("n", "<leader>ggs", "<cmd>Gitsigns stage_hunk<CR>")
vim.keymap.set("v", "<leader>ggs", ":Gitsigns stage_hunk<CR>")
vim.keymap.set("n", "<leader>ggu", "<cmd>Gitsigns undo_stage_hunk<CR>")
vim.keymap.set("n", "<leader>ggrr", "<cmd>Gitsigns reset_hunk<CR>")
vim.keymap.set("v", "<leader>ggrr", ":Gitsigns reset_hunk<CR>")
vim.keymap.set("n", "<leader>ggrb", "<cmd>Gitsigns reset_buffer<CR>")
vim.keymap.set("n", "<leader>ggrB", "<cmd>Gitsigns reset_buffer_index<CR>") -- this doesn't undo changes!!
vim.keymap.set("n", "<leader>ggp", "<cmd>Gitsigns preview_hunk<CR>")
vim.keymap.set("n", "<leader>ggb", '<cmd>lua require"gitsigns".blame_line{full=true}<CR>')
vim.keymap.set("n", "<leader>ggS", "<cmd>Gitsigns stage_buffer<CR>")
vim.keymap.set("n", "<leader>ggq", "<cmd>Gitsigns setqflist<CR>")
vim.keymap.set("n", "<leader>ggl", "<cmd>Gitsigns setloclist<CR>")

-- Text objects
vim.keymap.set("o", "lh", ":<C-U>Gitsigns select_hunk<CR>")
vim.keymap.set("x", "lh", ":<C-U>Gitsigns select_hunk<CR>")
