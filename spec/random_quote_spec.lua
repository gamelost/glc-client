require("../net/json")
local random_quote = require("../util/random_quote")
local quotes = io.open("../assets/loading/quotes.json", "rb")

describe("randomQuote", function()
  it("returns a string", function()
    assert(type(random_quote()) == "string", "is not a string")
  end)
end)
