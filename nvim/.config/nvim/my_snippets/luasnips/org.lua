-- cb to add a codeblock and auto expand

return {
  s(
    {
      trig = "cb",
      -- When wordTrig is set, snippets only expand as full words (lcb won't expand, cb will).
      wordTrig = true, -- true by default
      name = "code block",
      dscr = "",
      -- you can also add autosnippet in snipmate
      snippetType = "autosnippet", --https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md
    },
    fmt(
      [[
      #+BEGIN_SRC {}
        {}
      #+END_SRC
      ]],
      { i(1), i(0) }
    )
  ),
}
