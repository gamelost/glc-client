inspect = require("library/inspect")

function onChat(v)
  if not v.Sender then
    v.Sender = "ANNOUNCE"
  end
  console.log(v.Sender .. ': ' .. v.Message)
  if otherPlayers[clientid] then
    otherPlayers[clientid].msg = v.Message
    otherPlayers[clientid].msgtime = love.timer.getTime()
  end
end

function chat(text)
  glcd.send("chat", {Message=text, Sender = glcd.name})
  myPlayer.msg = text
  myPlayer.msgtime = love.timer.getTime()
end

function onPlayerGone(v)
  if v == nil then
    -- error from the server? we shouldn't see this
    print("error: onplayergone information was empty")
  else
    otherPlayers[v] = nil
  end
end

function onPlayerState(v)
  -- testing
  local clientid = v.ClientId
  if clientid == nil then
    -- error from the server? we shouldn't see this
    print("error: onplayerstate information was empty")
  elseif clientid ~= glcd.name then
    if otherPlayers[clientid] == nil then
      otherPlayers[clientid] = {name=clientid}
    end
    otherPlayers[clientid].state = v
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
  playerState=onPlayerState,
  updateZone=updateZone,
  error=onError
}
