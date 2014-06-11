require("library/nsq")

-- The sending channel which love pushes messages onto
local topic, sendchan = ...

-- nsq publishing connection
pub = NsqHttp:new()

while true do
  data = sendchan:demand()
  result = pub:publish(topic, data)
end
