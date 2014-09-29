local inspect = require("library/inspect")

function onChat(v, m)
  if not v.Sender then
    v.Sender = "ANNOUNCE"
  end
  console.log(v.Sender .. ': ' .. v.Message)
  if otherPlayers[m.ClientId] then
    otherPlayers[m.ClientId].msg = v.Message
    otherPlayers[m.ClientId].msgtime = love.timer.getTime()
  end
end

function chat(text)
  glcd.send("chat", {Message=text, Sender = glcd.name})
  myPlayer.msg = text
  myPlayer.msgtime = love.timer.getTime()
end

function onBroadcast(msg)
  if msg.request == "playerState" then
    glcd.send("playerState", myState)
  elseif msg.request == "fireBullet" then
    table.insert(bulletList, msg.bullet)
  end
end

function onPlayerGone(v)
  if v == nil then
    -- error from the server? we shouldn't see this
    print("error: onplayergone information was empty")
  else
    otherPlayers[v] = nil
  end
end

function onOtherPlayerState(v)
  -- testing
  local clientid = v.ClientId
  if clientid == nil then
    -- error from the server? we shouldn't see this
    print("error: onplayerstate information was empty")
  elseif clientid ~= glcd.clientid then
    if otherPlayers[clientid] == nil then
      otherPlayers[clientid] = {name=clientid}
      if v.Name then
        otherPlayers[clientid].name = v.Name
      else
        local tokens = string.gmatch(clientid, "-")
        otherPlayers[clientid].name = tokens[2]
      end
    end
    otherPlayers[clientid].state = v
  end
end

function onPlayerHeartbeat(obj)
  if ClientId ~= glcd.clientid then
    if otherPlayers[obj.ClientId] ~= nil then
      otherPlayers[obj.ClientId].status = obj.Status
    end
    if obj.Status == "QUIT" then
      otherPlayers[obj.ClientId] = nil
    end
  end
end

function updateZone(z)
  for _, zone in pairs(zones) do
    if zone.name == z.zone then
      zone.data(z)
    end
  end
end

function onError(err)
  print("error: " .. err)
end

return {
  sendChat=chat,
  chat=onChat,
  playerGone=onPlayerGone,
  otherPlayerState=onOtherPlayerState,
  updateZone=updateZone,
  playerHeartbeat=onPlayerHeartbeat,
  broadcast=onBroadcast,
  error=onError
}
