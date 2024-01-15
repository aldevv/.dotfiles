local handler = function(virtText, lnum, endLnum, width, truncate)
  local newVirtText = {}

  local suffix = ("  %d "):format(endLnum - lnum)
  local sufWidth = vim.fn.strdisplaywidth(suffix)
  local targetWidth = width - sufWidth
  local curWidth = 0
  for _, chunk in ipairs(virtText) do
    local chunkText = chunk[1]
    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
    if targetWidth > curWidth + chunkWidth then
      table.insert(newVirtText, chunk)
    else
      chunkText = truncate(chunkText, targetWidth - curWidth)
      local hlGroup = chunk[2]
      table.insert(newVirtText, { chunkText, hlGroup })
      chunkWidth = vim.fn.strdisplaywidth(chunkText)
      -- str width returned from truncate() may less than 2nd argument, need padding
      if curWidth + chunkWidth < targetWidth then
        suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
      end
      break
    end
    curWidth = curWidth + chunkWidth
  end
  table.insert(newVirtText, { suffix, "MoreMsg" })
  return newVirtText
end



require("ufo").setup({
  enable_get_fold_virt_text = true,
  fold_virt_text_handler = handler,
  close_fold_kinds = { "imports", "comment" },
  preview = {
    win_config = {
      winblend = 10,
    },

    mappings = {
      scrollU = '<C-u>',
      scrollD = '<C-d>',
      jumpTop = '[',
      jumpBot = ']',
      close = 'q',
      switch = '+',
      trace = '<CR>'
    },
  },
  provider_selector = function(bufnr, filetype, buftype)
    return { "treesitter", "indent" }
    -- return { "lsp", "treesitter" } -- main and fallback, indent is also available
  end,
})
vim.cmd("autocmd FileType org :UfoDetach")
