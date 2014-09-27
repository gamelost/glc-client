require("socket")
require("conf")
require("library/nsq")
require("library/json")
local inspect = require("library/inspect")

-- glcd heartbeat
local lastheartbeat = love.timer.getTime()

-- glcd handlers: use addHandler(func, messageType) to add a function
-- that will process the given message type
local handlers = {}

-- player name (for display purposes)
local playername = os.getenv("USER") or os.getenv("USERNAME")

-- the channels we will use to communicate with glcd
local glcdrecv = love.thread.newChannel()
local glcdsend = love.thread.newChannel()

function createClientID()
  local s = socket.udp()
  s:setpeername("8.8.8.8", 51)
  local ip, _ = s:getsockname()
  local id = ip .. "-" .. playername
  return id:sub(1,30)
end

-- clientid, used to identify the player to glcd
local clientid = createClientID()

function init()
  -- empty the channel, otherwise we may get notifications from stale
  -- events. these functions are blocking.
  NsqHttp:createChannel(settings.nsq_gamestate_topic, clientid)
  NsqHttp:emptyChannel(settings.nsq_gamestate_topic, clientid)

  -- poll glcd -- nonblocking
  local pollthread = love.thread.newThread("scripts/poll-glcd.lua")
  pollthread:start(clientid, glcdrecv)

  -- push glcd -- nonblocking
  local sendthread = love.thread.newThread("scripts/send-glcd.lua")
  sendthread:start(settings.nsq_daemon_topic, glcdsend)
end

function addHandler(command, handler)
  assert(handler ~= nil)
  handlers[command] = handler
end

function buildMessage(command, msg)
  local val = {
    ClientId = clientid,
    Type = command,
    Data = msg
  }
  return json.encode(val)
end

-- This is only used on quit, to ensure that we send messages before we
-- actually quit.
function sendSynchronous(command, msg)
  local data = buildMessage(command, msg)
  local pub = NsqHttp:new()
  pub:publish(settings.nsq_daemon_topic, data)
end

function send(command, msg)
  local data = buildMessage(command, msg)
  glcdsend:push(data)
end

local playerStatus = "OFFLINE"

function sendHeartbeat()
  local msg = {
    ClientId = clientid,
    Timestamp = os.time(),
    Status = playerStatus
  }

  if playerStatus == "QUIT" then
    sendSynchronous('heartbeat', msg)
  else
    send('heartbeat', msg)
  end
  lastheartbeat = love.timer.getTime()
end

function setPlayerStatus(newStatus)
  if playerStatus ~= newStatus then
    playerStatus = newStatus
    sendHeartbeat()
  end
end

function poll()
  -- heartbeat
  local elapsed = love.timer.getTime() - lastheartbeat
  if elapsed > 5.0 then
    sendHeartbeat()
  end

  -- Incoming
  local incoming = glcdrecv:pop()
  while incoming do
    msg = json.decode(incoming)
    if msg.Type ~= 'playerState' then
      print("incoming: " .. inspect(msg))
    end

    assert(#msg==0)

    if handlers[msg.Type] then
      handlers[msg.Type](msg.Data, msg)
    end
    incoming = glcdrecv:pop()
  end
end

return {
  init = init,
  send = send,
  poll = poll,
  setPlayerStatus = setPlayerStatus,
  addHandler = addHandler,
  clientid = clientid,
  name = playername
}
