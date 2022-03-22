local npairs = require("nvim-autopairs")
local Rule = require("nvim-autopairs.rule")
require("nvim-autopairs").setup({
    -- disable_filetype = { "TelescopePrompt" , "vim" },
    disable_filetype = { "TelescopePrompt" },
    disable_in_macro = true, -- disable when recording or executing a macro
    fast_wrap = {
        map = "<M-a>",
        chars = { "{", "[", "(" },
        pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
        offset = 0, -- Offset from pattern match
        end_key = "$",
        keys = "qwertyuiopzxcvbnmasdfghjkl",
        check_comma = true,
        highlight = "Search",
        highlight_grey = "Comment",
    },
})
-- https://github.com/windwp/nvim-autopairs/wiki/Custom-rules
npairs.clear_rules() -- removes all config for creating pairs
npairs.add_rules({

    -- these are for only on enter
    -- Rule("{", "}"):end_wise(function()
    --     return true
    -- end),
    --
    -- Rule("(", ")"):end_wise(function()
    --     return true
    -- end),
    --
    -- Rule("[", "]"):end_wise(function()
    --     return true
    -- end),
    -- arrow function
    Rule("%(.*%)%s*%=>$", " {  }", { "typescript", "typescriptreact", "javascript", "vue", "svelte" })
        :use_regex(true)
        :set_end_pair_length(2),
    -- add spaces when you press space inside (|)
    Rule(" ", " "):with_pair(function(opts)
        local pair = opts.line:sub(opts.col - 1, opts.col)
        return vim.tbl_contains({ "()", "[]", "{}" }, pair)
    end),

    Rule("```", "```", { "markdown", "vimwiki", "rmarkdown", "rmd", "pandoc" }),
})
