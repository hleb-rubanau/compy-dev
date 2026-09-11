-- LÖVE brings utf8 and a graphics context; a spec runs without
-- them, so shim the calls lib.terminal makes at construction and
-- while queueing output. utf8 is the real lua-utf8 rock, which
-- (like LÖVE's utf8) raises on a malformed sequence.
package.preload["utf8"] = function() return require("lua-utf8") end

local canvas = {}
_G.love = _G.love or {}
love.graphics = {
  newCanvas = function() return canvas end,
  getCanvas = function() return nil end,
  setCanvas = function() end,
  clear     = function() end,
  push      = function() end,
  origin    = function() end,
  pop       = function() end,
  getColor  = function() return 1, 1, 1, 1 end,
  setColor  = function() end,
  setFont   = function() end,
  print     = function() end,
  draw      = function() end,
  rectangle = function() end,
}
love.timer = { getTime = function() return 0 end }

local Terminal = require("lib.terminal")

local function new_term()
  local font = {
    getWidth  = function() return 10 end,
    getHeight = function() return 10 end,
  }
  return Terminal(200, 200, font, 10, 10)
end

describe("terminal output", function()
  it("queues each utf-8 codepoint of a normal write", function()
    local t = new_term()
    t:print("hi")
    assert.same({ "h", "i" }, t.stdin)
  end)

  -- Regression: io.write of a byte that is not valid UTF-8 used to
  -- raise (utf8.codes, terminal.lua) and take the whole console
  -- output down. The bad byte is dropped; the valid text survives.
  it("does not crash on a non-utf-8 byte, and keeps the good bytes", function()
    local t = new_term()
    assert.has_no.errors(function()
      t:print("A" .. string.char(0xFF) .. "B")
    end)
    assert.same({ "A", "B" }, t.stdin)
  end)
end)
