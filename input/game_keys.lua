-- Game Mode Keys Table
return {
  tab = function ()
    console.input.start()
    keymode = "console"
  end,
  v = function ()
    AvatarId = Gamelost.Player.changeAvatar(AvatarId)
    updateMyState({AvatarId = AvatarId})
  end,
  s = function ()
    AvatarState = AvatarState + 1
    if AvatarState > 2 then
      AvatarState = 0
    end
    updateMyState({AvatarState = AvatarState})
  end,
  [" "] = function ()
    glcd.send("broadcast",
      { request = "fireBullet"
      , bullet = Gamelost.Bullet.fireBullet(
                  { state=myState
                  , player=myPlayer
                  , speed=pSpeed
                  } )
      })
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
