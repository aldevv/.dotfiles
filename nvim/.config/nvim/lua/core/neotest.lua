require("neotest").setup({
    adapters = {
        -- require("neotest-python")({}), --  need to add env variable options
        require("neotest-vim-test")({}),
    },
    output = {
          enabled = true,
          open_on_run = "short"
    },
    summary = {
        mappings = {
            attach = "a",
            clear_marked = "M",
            clear_target = "T",
            expand = { "<CR>", "<2-LeftMouse>" },
            expand_all = "E",
            jumpto = "i",
            mark = "m",
            output = "o",
            run = "r",
            run_marked = "R",
            short = "O",
            stop = "u",
            target = "t",
        },
    },
})
