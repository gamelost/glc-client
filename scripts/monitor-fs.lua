require "love.timer"

q = ...

fs = require("util/fs")
fs.init()

-- brute force, yo
while true do
  zones = fs.refresh()
  q:supply(zones)
  love.timer.sleep(5)
end
