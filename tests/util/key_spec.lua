require('util.key')

local mock = require("tests.mock")

--- `Key.any_pressed` is the project-facing way to ask the
--- keyboard about a key that is not a modifier — the one
--- question `Key` could not answer, which sent every project to
--- `love.keyboard` directly. Its multi-argument form is OR, the
--- same as the device call it wraps: "is any of these down".
describe('Key.any_pressed', function()
  ---@diagnostic disable-next-line: missing-fields
  mock.mock_love({})

  before_each(function()
    for _, k in ipairs({ 'h', 'up', 'down', 'left', 'lshift',
      'rshift' }) do
      mock.unhold(k)
    end
  end)

  it('answers a single key', function()
    assert.is_false(Key.any_pressed('h'))
    mock.hold('h')
    assert.is_true(Key.any_pressed('h'))
  end)

  it('is OR across its arguments, like the device call',
    function()
    mock.hold('down')
    assert.is_true(Key.any_pressed('up', 'down'))
    assert.is_false(Key.any_pressed('up', 'left'))
  end)

  it('answers modifier key names too, unfolded', function()
    mock.hold('rshift')
    assert.is_true(Key.any_pressed('rshift'))
    assert.is_false(Key.any_pressed('lshift'))
    -- and the fold is still Key.shift()'s job
    assert.is_true(Key.shift())
  end)

  it('refuses a call with no key', function()
    assert.has_error(function() Key.any_pressed() end)
  end)
end)
