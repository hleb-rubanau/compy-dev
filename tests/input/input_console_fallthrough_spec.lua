-- Availability: changed by the Compy input API
-- (1.0.0-rc20260712).

-- What this file is about, in one paragraph.
--
-- A project run takes every input channel for the whole run
-- (doc/development/internals/event_dispatch_layers.md,
-- "Layer 2 — `love.<event>`, the active route's handler").
-- The route's walk already reports whether anybody consumed
-- (doc/development/internals/user_input.md, "Dispatch chain"),
-- and this file is about the event nobody did: it goes back
-- to the console, so a project whose whole body is
-- `print('help')` leaves the prompt below it typeable.
--
-- The gate is the SCREEN, not the keyboard. A project that
-- owns love.draw is painting over the console, so nothing
-- falls through to a prompt the user cannot see — which is
-- the one thing this deliberately does not restore.

local F = require('tests.helpers.input_fixture')

describe('input surface: inbound events — what nobody'
  .. ' consumed reaches the console #input', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  -- Backspace is the witness: it mutates the console's own
  -- content, and it travels love.handlers exactly as a real
  -- keystroke does (tests/helpers/input_session.lua). 'ab'
  -- becomes 'a' if the key arrived and stays 'ab' if the
  -- project route ate it.
  local function backspace_at_the_prompt()
    F.console:add_text('ab')
    F.session.press('backspace')
    return F.console:get_text()
  end

  -- The regression this pays: an unconsumed keypressed event
  -- falls through to the console
  -- (doc/development/internals/event_dispatch_layers.md, "What
  -- becomes of an event nobody consumed"), so the prompt stays
  -- live even though this project takes every channel for the
  -- whole run.
  it('a project that hooks nothing leaves the prompt live',
    function()
      F.activate_project({ })
      assert.same({ 'a' }, backspace_at_the_prompt())
    end)

  it('a project that owns the screen keeps the console deaf',
    function()
      F.activate_project({ draw = function() end })
      assert.same({ 'ab' }, backspace_at_the_prompt())
    end)

  -- The walk's own contract, restated from the other side:
  -- truthy consumes, and consuming means the console is not
  -- reached (doc/development/decisions/input.md,
  -- D-CHAIN-OF-3).
  it('a hook that consumes stops the walk at the project',
    function()
      local seen = 0
      local input = F.activate_project({ })
      input.hooks.keypressed = function()
        seen = seen + 1
        return true
      end
      assert.same({ 'ab' }, backspace_at_the_prompt())
      assert.equal(1, seen)
    end)

  -- The boundary the other cases do not touch: a hook the
  -- project registered ITSELF, through compy.input.hooks,
  -- and which returns falsey. Its author is presumed to know
  -- the convention, so falling through is what they asked
  -- for. A project's own love.* handler is a different case
  -- and is pinned in the seeded-hook group below.
  it('an explicit hook returning falsey falls through',
    function()
      local input = F.activate_project({ })
      input.hooks.keypressed = function() return false end
      assert.same({ 'a' }, backspace_at_the_prompt())
    end)

  -- The other side of the same boundary, and the reason a
  -- seeded handler is wrapped at all
  -- (doc/development/decisions/input.md, D-HOOKS-SEEDED,
  -- "AMENDED 2026-09-08 — a seeded handler consumes"). This
  -- handler returns nothing, as handlers written for LÖVE do;
  -- without the wrap that incidental return would decide
  -- whether the console hears the key, which is base parity
  -- lost by accident.
  it('a seeded legacy handler shields the console too',
    function()
      local got = 0
      F.activate_project({
        keypressed = function() got = got + 1 end,
      })
      assert.same({ 'ab' }, backspace_at_the_prompt())
      assert.equal(1, got)
    end)

  -- Ten against twelve: the console installs ten channels and
  -- the project route binds twelve, the two derived clicks
  -- having no console default by design
  -- (controller.lua, `_defaults`: "The derived clicks have
  -- none"). So an unconsumed derived click falls through to
  -- nothing, and that path must not raise.
  it('an unconsumed derived click falls through to nothing',
    function()
      F.activate_project({ })
      F.set_mouse_pos(10, 540)
      F.session.mousereleased(10, 540, 1, false, 1)
      assert.has_no.errors(function() F.love_update(0.5) end)
    end)
end)
