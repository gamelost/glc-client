require "love.timer"

fs = require("library/monitor-fs")
fs.init()

-- brute force, yo
while true do
  fs.refresh()
  love.timer.sleep(5)
end
