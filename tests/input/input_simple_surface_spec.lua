-- Availability: introduced with the simple surface
-- (1.0.0-rc20260712, SIMPLE-01).

-- The SIMPLE surface: compy.ask / on_answer / on_key / unask
-- (doc/development/decisions/input.md, D-SIMPLE-SURFACE). It is
-- a wrapper over the same widget the precise API drives, so
-- every case here drives the real project route and asserts on
-- the widget the precise API would show.

local F = require('tests.helpers.input_fixture')

describe('input surface: the basic API #input', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  describe('ask and on_answer', function()
    -- Positional args: ask(prompt, highlighter, text, cursor)
    -- all optional, per nagydany's original request.
    it('ask accepts positional args: prompt and text',
      function()
        local compy = F.activate_simple()
        local seen
        compy.on_answer = function(t) seen = t end
        compy.ask('name?', nil, 'ada')
        F.session.press('return')
        assert.equal('ada', seen)
        assert.equal('name?',
          F.widget.model:get_label())
      end)

    it('ask with only a prompt shows an empty widget',
      function()
        local compy = F.activate_simple()
        compy.on_answer = function() end
        compy.ask('label?')
        assert.is_true(F.is_widget_visible())
        assert.equal('label?',
          F.widget.model:get_label())
        assert.same({ '' }, F.widget:get_text())
      end)

    -- D-SIMPLE-SURFACE statement 5: a question concludes
    -- exactly once, through on_answer, and the answer is the
    -- text -- the same string the precise API's callbacks get
    -- (D-ONE-PAYLOAD).
    it('a question delivers its text to on_answer', function()
      local compy = F.activate_simple()
      local seen, called = nil, 0
      compy.on_answer = function(t)
        seen, called = t, called + 1
      end
      compy.ask('name?', nil, 'ada')
      F.session.press('return')
      assert.equal('ada', seen)
      assert.equal(1, called)
    end)

    -- The abandoned half of statement 5. Asserted as nil
    -- SPECIFICALLY, not as falsey: '' is truthy in Lua, so a
    -- project separates the two with `if text then`, and that
    -- separation is only real if abandonment is nil rather
    -- than the empty string.
    it('abandoning delivers nil, not an empty string',
      function()
        local compy = F.activate_simple()
        local seen, called = 'untouched', 0
        compy.on_answer = function(t)
          seen, called = t, called + 1
        end
        compy.ask('name?', nil, 'ada')
        F.session.press('escape')
        assert.is_nil(seen)
        assert.equal(1, called)
      end)

    -- Statement 4: the stub READS the namespace slot when it
    -- fires. Assigning on_answer after the ask must work, or
    -- the slot would be an argument wearing a callback's name.
    it('on_answer assigned after the ask still fires',
      function()
        local compy = F.activate_simple()
        local seen
        compy.ask(nil, nil, 'late')
        compy.on_answer = function(t) seen = t end
        F.session.press('return')
        assert.equal('late', seen)
      end)

    -- Statement 6: ask seats the one-shot disposal, so a
    -- question disposes of itself however it ends.
    it('a question takes itself down when answered', function()
      local compy = F.activate_simple()
      compy.on_answer = function() end
      compy.ask(nil, nil, 'x')
      assert.is_true(F.is_widget_visible())
      F.session.press('return')
      assert.is_false(F.is_widget_visible())
    end)

    -- SIMPLE-01-05, and the case that proves dispose-then-
    -- notify landed: the uninstaller runs BEFORE on_answer, so
    -- a follow-up question asked from inside it is not closed
    -- by the flow that called it.
    it('a re-ask from inside on_answer survives the flow',
      function()
        local compy = F.activate_simple()
        local asked = 0
        compy.on_answer = function()
          asked = asked + 1
            if asked == 1 then
            compy.ask('again?')
          end
        end
        compy.ask('first?', nil, 'a')
        F.session.press('return')
        assert.is_true(F.is_widget_visible())
        assert.equal('again?', F.widget.model:get_label())
      end)
  end)

  describe('what ask restores', function()
    -- Owner ruling 2026-09-09: ask may use the lifecycle
    -- flags, and the configuration has to be restored on
    -- answer. The project's own seating is what it finds
    -- afterwards, not ask's.
    it('the lifecycle flags come back after an answer',
      function()
        local compy = F.activate_simple()
        local input = F.compy_input()
        input.configure({ clear_on_submit = false })
        compy.on_answer = function() end
        compy.ask(nil, nil, 'q')
        F.session.press('return')
        -- ask seated clear+hide on both verbs; if the restore
        -- did not run, this submit would empty the widget.
        input.show({ text = 'kept' })
        F.session.press('return')
        assert.same({ 'kept' }, F.widget:get_text())
      end)

    -- The widget callbacks ask overwrites are its own
    -- boilerplate, so a project's precise-API callback must
    -- survive a question that borrowed the slot.
    it('an advanced on_text_entered survives a question',
      function()
        local compy = F.activate_simple()
        local input = F.compy_input()
        local precise = { }
        input.callbacks.on_text_entered = function(t)
          precise[#precise + 1] = t
        end
        compy.on_answer = function() end
        compy.ask(nil, nil, 'q')
        F.session.press('return')
        assert.same({ }, precise)
        input.show({ text = 'after' })
        F.session.press('return')
        assert.same({ 'after' }, precise)
      end)
  end)

  describe('on_key', function()
    -- SIMPLE-01-06, and the return value is the whole design:
    -- a key the program CLAIMS never reaches editing.
    it('a claimed key never reaches the widget', function()
      local compy = F.activate_simple()
      local seen
      compy.on_answer = function() end
      compy.on_key = function(k) seen = k; return true end
      compy.ask(nil, nil, 'abc')
      F.session.press('backspace')
      assert.equal('backspace', seen)
      assert.same({ 'abc' }, F.widget:get_text())
    end)

    -- ...and the half that makes the design work: a key the
    -- program DECLINES still edits. Nothing in ask knows that
    -- backspace is an editing key.
    it('a declined key still edits', function()
      local compy = F.activate_simple()
      compy.on_answer = function() end
      compy.on_key = function() return false end
      compy.ask(nil, nil, 'abc')
      F.session.press('backspace')
      assert.same({ 'ab' }, F.widget:get_text())
    end)

    -- With no on_key set at all, ask is transparent: the
    -- widget behaves exactly as the precise API's show does.
    it('an unset on_key leaves editing alone', function()
      local compy = F.activate_simple()
      compy.on_answer = function() end
      compy.ask(nil, nil, 'abc')
      F.session.press('backspace')
      assert.same({ 'ab' }, F.widget:get_text())
    end)

    -- The requester's own exclusion, and D-COMBO-SHAPE's: a
    -- modifier alone is never reported, only in conjunction.
    it('a bare modifier is never reported', function()
      local compy = F.activate_simple()
      local fired = 0
      compy.on_answer = function() end
      compy.on_key = function()
        fired = fired + 1
        return true
      end
      compy.ask()
      F.session.press('lctrl')
      assert.equal(0, fired)
    end)

    -- A key arriving as text is textinput's, not on_key's --
    -- reporting it would fire on every letter typed, which is
    -- the trap the decoding note recorded.
    it('a key arriving as text is not reported', function()
      local compy = F.activate_simple()
      local fired = 0
      compy.on_answer = function() end
      compy.on_key = function()
        fired = fired + 1
        return true
      end
      compy.ask()
      F.session.type('a')
      assert.equal(0, fired)
      assert.same({ 'a' }, F.widget:get_text())
    end)

    -- LOVE's own argument list (D-LOVE-ARGS), which is what
    -- the combo string was dropped for: the repeat flag has to
    -- have a position, and repeats are DELIVERED
    -- (D-SIMPLE-SURFACE statement 7).
    it('on_key receives the repeat flag and sees repeats',
      function()
        local compy = F.activate_simple()
        local seen = { }
        compy.on_answer = function() end
        compy.on_key = function(k, _, isr)
          seen[#seen + 1] = { k, isr }
          return true
        end
        compy.ask()
        F.session.press('f1')
        F.session.repeat_press('f1')
        assert.same({ { 'f1', false }, { 'f1', true } }, seen)
      end)
  end)

  describe('collisions and withdrawal', function()
    -- Owner ruling 2026-09-09: ask RAISES rather than
    -- chaining, because the project is the one that should
    -- decide -- and nothing is blocked, since the precise API
    -- builds whatever it wants.
    it('ask raises when a keypressed hook is installed',
      function()
        local compy = F.activate_simple({
          keypressed = function() end,
        })
        assert.has_error(function() compy.ask() end)
      end)

    -- unask is the programmatic withdrawal: it disposes and
    -- restores, and it concludes NOTHING -- on_answer(nil) is
    -- the user abandoning, and a program that withdrew its own
    -- question already knows.
    it('unask takes the question back without concluding',
      function()
        local compy = F.activate_simple()
        local fired = 0
        compy.on_answer = function() fired = fired + 1 end
        compy.ask(nil, nil, 'q')
        compy.unask()
        assert.equal(0, fired)
        assert.is_false(F.is_widget_visible())
      end)

    -- ...and it really uninstalled: a key that on_key would
    -- have claimed no longer reaches it.
    it('unask uninstalls the key hook', function()
      local compy = F.activate_simple()
      local fired = 0
      compy.on_answer = function() end
      compy.on_key = function()
        fired = fired + 1
        return true
      end
      compy.ask(nil, nil, 'q')
      compy.unask()
      F.compy_input().show({ text = 'abc' })
      F.session.press('backspace')
      assert.equal(0, fired)
      assert.same({ 'ab' }, F.widget:get_text())
    end)
  end)
end)
