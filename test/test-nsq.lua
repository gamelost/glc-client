require "library/nsq"
require "os"
require "settings"
require "socket"

queue = ...

n = NsqHttp:new()

print("NSQ: testing nsq")
-- print("NSQ: creating topic: " .. n:createTopic("testing").status_txt)
-- print("NSQ: publishing to topic: " .. n:publish("testing", "{}"))
-- print("NSQ: deleting topic: " .. n:deleteTopic("testing").status_txt)

local nsq = require "library/nsqc"

-- local clientid = uuid():sub(1,30)
local s = socket.udp()
s:setpeername("8.8.8.8", 51)
local ip, _ = s:getsockname()
print("IP: ", ip)
local clientid = ip .. "-" .. os.getenv("USER")

clientid = clientid:sub(1,30)

print("NSQ: Client ID: '" .. clientid .. "'")

print("NSQ: Creating client queue: ", n:createTopic(clientid))
print("NSQ: Creating client channel: ", n:createChannel(clientid, "main"))

local fullclientid = settings.nsq_host .. ":" .. settings.nsq_port .. ":" .. clientid

print("NSQ: Notifying server:", n:publish("glcd-server", "{\"client\":\"" .. fullclientid .. "\"}"))

print("NSQ: Pinging server:", n:publish("glcd-server", "{\"client\":\"" .. fullclientid .. "\",\"command\":\"ping\"}"))

print("NSQ: Connecting to server . . .")

local c = nsq.new(settings.nsq_host, settings.nsq_port)

c:subscribe(clientid, "main")

local handler = function(job)
  print(string.format(
      "got job %s with %d attempts and body %s",
      job.id, job.attempts, job.body
      ))
  -- mark job as complete
  return true
end

while true do
  c:consume_one(handler)
end
