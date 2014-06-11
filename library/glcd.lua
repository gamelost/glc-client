require("socket")
require("library/json")
require("conf")
require("library/nsq")

local underscore = require("library/underscore")
local inspect = require("library/inspect")

-- generate users' client ID
local s = socket.udp()
s:setpeername("8.8.8.8", 51)
local ip, _ = s:getsockname()
local playername = os.getenv("USER")

-- clientid: No longer just the playername.
local clientid = ip .. "-" .. playername
clientid = clientid:sub(1,30)

-- poll glcd (the server)
local pollthread = love.thread.newThread("scripts/poll-glcd.lua")
local glcdrecv = love.thread.newChannel()

-- Create and empty the channel, so we don't get old stuff from the last time
-- we were connected.
--
-- We do this first, and blocking, so we don't accidentally empty anything we
-- actually want.
NsqHttp:createChannel(settings.nsq_gamestate_topic, clientid)
NsqHttp:emptyChannel(settings.nsq_gamestate_topic, clientid)

-- poll glcd (the server)
pollthread = love.thread.newThread("scripts/poll-glcd.lua")
glcdrecv = love.thread.newChannel()
pollthread:start(clientid, glcdrecv)

-- Send messages (since network hangs main love thread)
local sendthread = love.thread.newThread("scripts/send-glcd.lua")
local glcdsend = love.thread.newChannel()
sendthread:start(settings.nsq_daemon_topic, glcdsend)

-- heartbeat
local lastheartbeat = love.timer.getTime()

-- handlers
local handlers = {}

function addHandler(command, handler)
  assert(handler ~= nil)
  handlers[command] = handler
end

function send(command, msg)
  local val = {
    ClientId = clientid,
    Type = command,
    Data = msg
  }
  local data = json.encode(val)
  glcdsend:push(data)
end

function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return table[element]
    end
  end
  return nil
end

function poll()
  -- heartbeat
  local elapsed = love.timer.getTime() - lastheartbeat
  if elapsed > 5.0 then
    send('heartbeat', { beat = "ba-dum"})
    lastheartbeat = love.timer.getTime()
  end

  -- Incoming
  local incoming = glcdrecv:pop()
  while incoming do
    msg = json.decode(incoming)
    --print("incoming: " .. inspect(msg))

    assert(#msg==0)

    if handlers[msg.Type] then
      handlers[msg.Type](msg.Data, msg)
    end

    incoming = glcdrecv:pop()
  end
end

return {
  send = send,
  poll = poll,
  addHandler = addHandler,
  clientid = clientid,
  name = playername
}
