-- A generic Command function to use as metatable.
return {
  new = function(command)
    return setmetatable(command, Command)
  end,
  execute = function()
    return 0
  end
}
