local nsq = require("library/nsqc")
require "conf"

-- The sending channel which love pushes messages onto
local topic, sendchan = ...

local c = nsq.new(settings.nsq_host, settings.nsq_port)

c:disableHeartbeat()
-- nsq publishing connection
while true do
  local data = sendchan:demand()
  c:publish(topic, data)
end
