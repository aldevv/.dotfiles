local vimcmd = {

  -- When you call list:append() this function is called and the return
  -- value will be put in the list at the end.
  --
  -- which means same behavior for prepend except where in the list the
  -- return value is added
  --
  -- @param possible_value string only passed in when you alter the ui manual
  add = function(possible_value)
    -- get the current line idx
    local idx = vim.fn.line(".")

    -- read the current line
    local cmd = vim.api.nvim_buf_get_lines(0, idx - 1, idx, false)[1]
    if cmd == nil then
      return nil
    end

    return {
      value = cmd,
      context = {},
    }
  end,

  --- This function gets invoked with the options being passed in from
  --- list:select(index, <...options...>)
  --- @param list_item {value: any, context: any}
  --- @param list { ... }
  --- @param option any
  select = function(list_item, list, option)
    vim.cmd(list_item.value)
  end

}

local term = {
  select = function(list_item, list, option)
    -- row not working
    -- local window_name = "term" .. list_item.context.row

    -- get the list_item position in the list
    local list_item_idx = -1
    for i, v in ipairs(list.items) do
      if v.value == list_item.value then
        list_item_idx = i
        break
      end
    end

    local window_name = "term" .. list_item_idx

    local window_exists = vim.fn.system("tmux list-windows -F '#{window_name}' | grep '^" .. window_name .. "' | wc -l")
        :gsub("\n", "") == "1"

    if not window_exists then
      vim.fn.system("tmux neww -n " .. window_name .. " -d")
    end
    vim.fn.system("tmux send-keys -t '" .. window_name .. "' '" .. list_item.value .. "' Enter")
    vim.fn.system("tmux select-window -t " .. window_name)
  end

}

return {
  vimcmd = vimcmd,
  term = term
}
