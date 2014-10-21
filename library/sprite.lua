Sprite = {spriteList={}}
Sprite.prototype = {
  __index={
    spriteType="Sprite",
    append=function(obj)
      table.insert(Sprite.spriteList,obj)
    end,
    update=function()
    end,
    draw=function()
    end
  }
}

function Sprite.new(obj)
  setmetatable(obj, Sprite.prototype)
  return obj
end

return Sprite
