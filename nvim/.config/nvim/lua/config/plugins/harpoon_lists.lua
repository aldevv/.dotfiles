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
  end,
}

local runOverseer = function(task_name, cmd)
  -- run overseer task based on command
  vim.print(cmd)
  require("overseer")
      .new_task({
        name = task_name .. ": " .. cmd,
        cmd = cmd,
        components = {
          "on_output_summarize",
          "on_exit_set_status",
          "on_complete_notify",
          {
            "on_output_quickfix",
            open = true,
          },
          "default",
        },
      })
      :start()
end

local command = {
  select = function(list_item, list, option)
    runOverseer("command", list_item.value)
  end,
}

local test = {
  select = function(list_item, list, option)
    runOverseer("test", list_item.value)
  end,
}

return {
  vimcmd = vimcmd,
  command = command,
  test = test,
}
