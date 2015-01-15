local Command = require('input/command')

local up, down, right, left

up = { execute = function ( actor )
  actor.moveUp()
end }
down = { execute = function ( actor )
  actor.moveDown()
end }
left = { execute = function ( actor )
  actor.moveLeft()
end }
right = { execute = function ( actor )
  actor.moveRight()
end }

return {
  UpCommand    = Command.new(up),
  DownCommand  = Command.new(down),
  LeftCommand  = Command.new(left),
  RightCommand = Command.new(right)
}
