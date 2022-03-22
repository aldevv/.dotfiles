local M = {}
function M.quickfix_toggle_definition()
    vim.cmd([[
        function! ToggleQuickFix(staywindow)
          if empty(filter(getwininfo(), 'v:val.quickfix'))
            copen
            if (a:staywindow == 0)
              execute "normal! \<c-w>k"
            endif
          else
            cclose
          endif
        endfunction

            ]])
end

function M.location_toggle_definition()
    vim.cmd([[
        function! ToggleLocation(staywindow)
          if empty(filter(getwininfo(), 'v:val.quickfix'))
            lopen
            if (!a:staywindow)
              execute "normal! \<c-w>k"
            endif
          else
            lclose
          endif
        endfunction

    ]])
end

return M

