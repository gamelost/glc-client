require "library/nsq"
require "os"
require "settings"
require "json"

local clientid, recv = ...

local nsq = require "library/nsqc"

local c = nsq.new(settings.nsq_host, settings.nsq_port)

c:subscribe(clientid, "main")

local handler = function(job)
  print(string.format(
      "got job %s with %d attempts and body %s",
      job.id, job.attempts, job.body
      ))
  recv:push(job.body)
  return true
end

while true do
  c:consume_one(handler)
end
