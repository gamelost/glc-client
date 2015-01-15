local Sprite = require('graphics/sprites/sprite')

describe('Sprite', function()
  it("Sprite.new creates an instance when passed width, height, and zoneid", function()
    assert(Sprite.new{width=20,height=20,zoneid=1})
  end)

  describe("New Sprite", function()
    -- it("has spriteUpdate", function()
    --   sprite = Sprite.new{width=20,height=20,zoneid=1}
    --   assert(sprite:spriteUpdate(), "can call spriteUpdate")
    -- end)
    -- it("spriteUpdate requires update function", function()
    --   sprite = Sprite.new{width=20,
    --   height=20,
    --   zoneid=1,
    --   update=function()
    --   end}
    --   assert(sprite:spriteUpdate(), "can call spriteUpdate")
    -- end)
  end)

  describe("Sprite.inherit", function()

    -- Need to be cautious here. When extending from Sprite, we are losing the
    -- ability to call setmetatable, which MUST have __index
    default_data = {width=20,height=20,zoneid=1}
    it("Inheriting from Sprite can still call new", function()
      Player = Sprite.inherit{drawPlayer=function() end}
      Player.new = function(args)
        -- set up original Sprite data and then set metatable
        obj = Sprite.new(args)
        return setmetatable(args,Player)
      end
      assert(Player.new(default_data))
    end)
  end)
end)
