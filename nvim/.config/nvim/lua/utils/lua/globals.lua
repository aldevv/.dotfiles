--
-- these are loaded so you can do : lua put({1,2,3})
function _G.put(...)
  local objects = {}
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  print(table.concat(objects, '\n'))
  return ...
end

function _G.t(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end


