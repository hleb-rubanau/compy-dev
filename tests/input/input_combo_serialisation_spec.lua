-- Availability: introduced with the Compy input API
-- (1.0.0-rc20260712) — combo normalisation has no
-- predecessor; the shortcut behaviour it drives is
-- asserted in
-- input_shortcuts_click_spec.lua.

-- Stub view.view before anything requires it: the real module
-- (src/view/view.lua) calls gfx.newFont() at load time (gfx =
-- love.graphics), which needs a graphics context absent in
-- tests. This minimal stub mirrors the fields the controller
-- path touches.
package.preload['view.view'] = function()
  View = {
    prev_draw = nil,
    main_draw = nil,
    snapshot = nil,
    clear_snapshot = function() end,
    draw = function() end,
    drawFPS = function() end,
  }
end

-- combo_string is a free function over the device, but
-- requiring the controller pulls the module graph that reads
-- love at load time.
local mock = require('tests.mock')
mock.mock_love({
  state = {
    app_state = 'ready',
    user_input = nil,
    editor = nil,
  },
  DEBUG = false,
  PROFILE = false,
  -- quit is a no-op: we assert the handlers don't crash, not
  -- quit behaviour.
  event = { quit = function() end },
})

require('controller.controller')

-- (serialize-vs-match): this pins that combo matching runs
-- through per-keypress serialisation. A standing design
-- alternative is to build registration-time dispatcher
-- closures once instead of serialising on every event.
describe('input surface: inbound events — combo serialisation'
  .. ' #input', function()
  local cs = Controller.combo_string

  -- The modifiers come from the keyboard, so a case holds them
  -- on the device rather than handing over a table
  -- (doc/development/decisions/input.md, D-ASK-THE-DEVICE).
  before_each(function() mock.release_keys() end)

  it('bare key escape', function()
    assert.equal('escape', cs('escape'))
  end)

  it('bare key s', function()
    assert.equal('s', cs('s'))
  end)

  -- Registration canonicalises to lower case
  -- (doc/development/decisions/input.md, D-COMBO-TABLES: a
  -- project registers 'Ctrl+S' "and still match"), so dispatch
  -- has to emit lower case or the slot is unreachable. Only
  -- textinput can deliver an upper-case trigger — keypressed
  -- tokens are LÖVE key constants and are already lower.
  it('an upper-case trigger serialises lower', function()
    assert.equal('i', cs('I'))
  end)

  it('an upper-case trigger folds under modifiers', function()
    mock.hold('lshift')
    assert.equal('shift+i', cs('I'))
  end)

  it('ctrl+s from lctrl held', function()
    mock.hold('lctrl')
    assert.equal('ctrl+s', cs('s'))
  end)

  -- The right-hand key folds to the same generic name. This is
  -- the case the one-argument mock could not express at all.
  it('ctrl+s from rctrl held', function()
    mock.hold('rctrl')
    assert.equal('ctrl+s', cs('s'))
  end)

  it('alt+shift+f4 ordering', function()
    mock.hold('lalt')
    mock.hold('lshift')
    assert.equal('alt+shift+f4', cs('f4'))
  end)

  it('ctrl before alt precedence', function()
    mock.hold('lalt')
    mock.hold('lctrl')
    assert.equal('ctrl+alt+s', cs('s'))
  end)

  it('all modifiers: ctrl alt shift', function()
    mock.hold('lctrl')
    mock.hold('lalt')
    mock.hold('lshift')
    assert.equal('ctrl+alt+shift+s', cs('s'))
  end)
end)
