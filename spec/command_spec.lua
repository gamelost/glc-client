local Command = require ('input/command')

describe("Command", function()
  it('Command', function()
    UpCommand = setmetatable({}, {__index = Command})

    assert.are.equal(UpCommand.execute(), Command.execute())
  end)

  describe('UpCommand', function()
    up = {
      execute = function ()
        return 5
      end
    }

    it("returns the new number", function()
      UpCommand = setmetatable(up, {__index = Command})
      assert.are.equal(5, UpCommand.execute())
    end)

    it("does not overwrite the Command", function()
      UpCommand = setmetatable(up, {__index = Command})
      assert.are_not.equal(UpCommand.execute(), Command.execute())
    end)
  end)

  describe("Metatabled Commands", function()
    local metatabled_commands = require("input/move_commands")
    it("works", function()
      assert(metatabled_commands.UpCommand)
    end)
  end)
end)
