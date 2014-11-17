local Sprite = require('graphics/sprites/sprite')
local _ = require('util/underscore')

describe('Sprite', function()
  local sprite
  it("Sprite.new creates an instance when passed width, height, and zoneid", function()
    assert(Sprite.new{width=20,height=20,zoneid=1})
  end)

  describe("New Sprite", function()
    args = {width=20,height=20,zoneid=1}
    it("is endued with update", function()
      sprite = Sprite.new(args)
      assert(sprite.update, "can call update")
    end)
    it("is endued with draw", function()
      assert(sprite.draw, "can call update")
    end)
    it("is endued with updateState", function()
      assert(sprite.updateState, "can call update")
    end)

    it("overriding a function is possible", function()
      local with_update = _.extend({update=function()
        return 5
      end}, args)
      sprite = Sprite.new(with_update)
      assert(sprite:update() == 5, "can call update")
    end)
  end)

  describe("Sprite.inherit", function()
    local default_data = {width=20,height=20,zoneid=1}
    local Player = Sprite.inherit{drawPlayer=function() end}
    Player.new = function(args)
      -- set up original Sprite data and then set metatable
      local obj = Sprite.new(args)
      return setmetatable(args, Player)
    end
    it("from Sprite can still call new", function()
      assert(Player.new(default_data), "it didn't work")
    end)
    it("drawPlayer", function()
      local p = Player.new(default_data)
      assert(p.drawPlayer, "couldn't be called")
    end)

    it("__base prototype", function()
      assert(Player.__base, "doesn't exist")
    end)

  end)
end)
