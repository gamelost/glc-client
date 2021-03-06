-- Game Mode Keys Table
return {
  tab = function ()
    console.input.start()
    keymode = "console"
  end,
  v = function ()
    myPlayerState.AvatarId = Gamelost.Player.changeAvatar(AvatarId)
    updateMyState({AvatarId = myPlayerState.AvatarId})
  end,
  s = function ()
    myPlayerState.AvatarState = myPlayerState.AvatarState + 1
    if myPlayerState.AvatarState > 2 then
      myPlayerState.AvatarState = 0
    end
    updateMyState({AvatarState = myPlayerState.AvatarState})
  end,
  [" "] = function ()
    bullet = Gamelost.Bullet.fireBullet{ player=myPlayerState,
                                         speed=pSpeed }
    glcd.send("broadcast",
              { request = "fireBullet",
                bullet = bullet })
  end,
  x = function ()
    px, py = randomZoneLocation()
    updateMyState({X = px, Y = py})
  end,
  l = function ()
    local currZoneId, currZone = getZoneOffset(px, py)
    if currZone then
      currZone.state.toggle_next_layer(currZone.state.tiles)
    end
  end,
  p = function()
    if love.keyboard.isDown("lctrl") then
      local screenshot = love.graphics.newScreenshot()
      screenshot:encode("screenshot" .. os.date("%d-%m-%Y-%H-%M-%S") .. ".png")
    end
  end,
}
