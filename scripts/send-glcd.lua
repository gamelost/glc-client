require("library/nsq")

-- The sending channel which love pushes messages onto
local topic, sendchan = ...

-- nsq publishing connection
local pub = NsqHttp:new()

while true do
  local data = sendchan:demand()
  pub:publish(topic, data)
end
