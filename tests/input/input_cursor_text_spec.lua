-- The suite's own three groups, named to match the guide's
-- three surfaces: "inbound events" for interception,
-- "widget control" for driving the widget, "widget callbacks"
-- for what it reports back. This file is the second.
--
-- Availability: introduced with the Compy input API
-- (1.0.0-rc20260712) — covers the compy.input surface.

-- Cursor and text surface: get_cursor / set_cursor / set_text,
-- driven through F.compy_input() — exactly what a
-- project sees (doc/input_api.md, "Live changes";
-- doc/development/internals/user_input.md, "Cursor manipulation
-- and \"reset\""). Implementation:
-- model/input/userInputModel.lua,
-- controller/userInputController.lua.

local F = require('tests.helpers.input_fixture')

describe('input surface: widget control — cursor and' ..
  ' text #input',
  function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)


  -- These three are non-assignable methods (NOT in
  -- INPUT_CALLBACKS), so they ride the same frozen-surface
  -- boundary as show/hide —
  -- doc/development/decisions/input.md, D-FROZEN-SHELL
  -- (what a project may assign).


  describe("get_cursor", function()
    -- doc/development/internals/user_input.md, "Cursor
    -- manipulation and \"reset\"": active → 1-based
    -- (line, col); hidden → nil.
    it('reports 1-based (line, col) when active',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        assert.same({ 1, 6 }, { input.get_cursor() })
      end)

    -- The pair above proves the report is 1-based ONCE. This
    -- case proves it keeps TRACKING: the reported position
    -- follows real edits (a typed character, a deletion) rather
    -- than being a constant that happens to match the opening
    -- state.
    -- activate_project, not compy_input alone: this case TYPES,
    -- so it needs the route a real project's widget is fed
    -- through. Reading the surface needs no route; delivery
    -- does.
    it('keeps reporting the cursor as the text is edited',
      function()
        local input = F.activate_project()
        input.show({ text = 'hi' })
        assert.same({ 1, 3 }, { input.get_cursor() })
        F.session.type('!')
        assert.same({ 1, 4 }, { input.get_cursor() })
        F.session.press('backspace')
        assert.same({ 1, 3 }, { input.get_cursor() })
      end)

    -- Multiline: the LINE half of the pair has to move too, or
    -- a single-line-only report would pass every case above.
    it('reports the line on multiline text', function()
      local input = F.compy_input()
      input.show({ text = { 'ab', 'cd' } })
      assert.same({ 2, 3 }, { input.get_cursor() })
    end)

    -- Shown-with-text first, THEN hidden: without that setup a
    -- nil return would be indistinguishable from "the widget
    -- was empty and never active", which is not the claim being
    -- made.
    it('returns nil when hidden', function()
      local input = F.compy_input()
      input.show({ text = 'hello' })
      assert.is_not_nil(input.get_cursor())
      input.hide()
      assert.is_nil(input.get_cursor())
    end)
 end)

 describe("set_cursor", function()

    -- doc/development/internals/user_input.md, "Cursor
    -- manipulation and \"reset\"": move; out-of-range
    -- clamps to the valid range.
    
    -- activate_project: the case types to prove the caret is
    -- seated, so it needs the project route to deliver.
    it('moves the cursor', function()
      local input = F.activate_project()
      input.show({ text = 'lemon' })
      input.set_cursor(1, 3)
      assert.same({ 1, 3 }, { input.get_cursor() })
      -- The caret is really seated, not merely reported back:
      -- typing lands at the caret. `col` counts positions
      -- BETWEEN characters (1 .. #line + 1), so col 3 is
      -- between 'e' and 'm' (doc/input_api.md, "Live changes").
      F.session.type('X')
      assert.same({ 'leXmon' }, F.widget:get_text())
    end)

    -- Discriminating: seat the cursor at col 2 first, so a
    -- clamp-to-line-end (col 6) is distinguishable from
    -- move_cursor's fallback-to-previous (would stay col 2).
    -- Proves set_cursor_pos clamps rather than no-ops.
    it('clamps an over-range column', function()
      local input = F.compy_input()
      input.show({ text = 'hello' })
      input.set_cursor(1, 2)
      input.set_cursor(1, 999)
      local _, c = input.get_cursor()
      assert.same(6, c) -- 'hello' end (len 5 + 1)
    end)

    -- 'привет' is 6 characters in 12 bytes, so a
    -- byte-counted clamp would accept anything up to 13 and
    -- leave the caret
    -- past the end of the line. col is a caret position between
    -- CHARACTERS (doc/input_api.md, "Live changes"), which is
    -- also what every other cursor move in the model counts.
    it('clamps an over-range column in characters, not bytes',
      function()
        local input = F.compy_input()
        input.show({ text = 'привет' })
        input.set_cursor(1, 2)
        input.set_cursor(1, 10)
        local _, c = input.get_cursor()
        assert.same(7, c) -- 6 characters + 1
      end)

    -- The same bound on the other path into it: set_text's
    -- keep_cursor landing, when the new content is shorter.
    it('keep_cursor clamps in characters too', function()
      local input = F.compy_input()
      input.show({ text = 'hello there' })
      input.set_cursor(1, 10)
      input.set_text('привет', true)
      local _, c = input.get_cursor()
      assert.same(7, c) -- 6 characters + 1
    end)

    it('clamps an over-range line', function()
      local input = F.compy_input()
      input.show({ text = 'hello' })
      input.set_cursor(999, 2)
      local l = input.get_cursor()
      assert.same(1, l) -- single line: clamps to 1
    end)

    -- A cursor is {line, col}, two numbers. A malformed one is
    -- an authoring error and is refused the way a bad config
    -- KEY is (doc/development/decisions/input.md,
    -- D-UNKNOWN-RAISES) — with a framework message naming the
    -- expected shape, not a raw arithmetic error from inside
    -- math.min. This is distinct from an out-of-RANGE number,
    -- which is well-formed and still clamps (cases above).
    it('raises a framework error on a nil position',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        local _, err = pcall(function()
          input.set_cursor(nil, nil)
        end)
        assert.is_truthy(
          string.find(tostring(err), 'cursor', 1, true))
        assert.is_falsy(
          string.find(tostring(err), 'math', 1, true))
      end)

    it('raises on a partial position', function()
      local input = F.compy_input()
      input.show({ text = 'hello' })
      assert.has_error(function()
        input.set_cursor(1, nil)
      end)
    end)

    -- doc/input_api.md, "Live changes": hidden set_cursor
    -- no-ops and warns.
    it('while hidden warns and no-ops', function()
      local input = F.compy_input()
      local warned = 0
      local ow = Log.warn
      Log.warn = function() warned = warned + 1 end
      input.set_cursor(1, 2)
      Log.warn = ow
      assert.equal(1, warned)
      assert.is_nil(input.get_cursor())
    end)
 end)

 describe("get_text", function()

    -- doc/input_api.md, "Live changes": the read the surface
    -- never had. It answers a STRING, the spelling
    -- on_text_entered delivers, because set_text takes either
    -- spelling and treats them as the same thing — so a
    -- string round-trips and needs no type the guide does not
    -- already name.
    it('reports the content seated by show', function()
      local input = F.compy_input()
      input.show({ text = 'hello' })
      assert.same('hello', input.get_text())
    end)

    -- THE case the entry exists for. Everything else here a
    -- project could already reconstruct from what it seated;
    -- what the user typed and did not submit was unreadable,
    -- which is why "keep it yourself" was not followable
    -- advice (doc/input_api.md, "hide()").
    -- activate_project, not compy_input: this case TYPES.
    it('reports what the user typed, not only what was seated',
      function()
        local input = F.activate_project()
        input.show({ text = 'hi' })
        F.session.type('!')
        assert.same('hi!', input.get_text())
      end)

    -- Multiline is the one place the return shape is visible:
    -- lines are joined, not dropped, and the result feeds
    -- straight back into set_text, which splits it again.
    it('joins multiline content with newlines', function()
      local input = F.compy_input()
      input.show({ text = { 'ab', 'cd' } })
      assert.same('ab\ncd', input.get_text())
    end)

    -- Empty content is '' and hidden is nil: two different
    -- answers, so a project can tell "nothing typed" from
    -- "nothing to report". Pinned as a pair, or one could
    -- collapse into the other unnoticed.
    it('answers an empty string when up and empty', function()
      local input = F.compy_input()
      input.show()
      assert.same('', input.get_text())
    end)

    -- Shown-with-text first, THEN hidden — same reason as
    -- get_cursor's case: a nil from a widget that was never
    -- active proves nothing. nil, and NOT a warning: a read of
    -- "nothing to report" is not a refused mutation
    -- (doc/development/internals/user_input.md, "Cursor
    -- manipulation and \"reset\"", the rule get_cursor
    -- follows).
    it('returns nil when hidden', function()
      local input = F.compy_input()
      input.show({ text = 'hello' })
      assert.is_not_nil(input.get_text())
      input.hide()
      assert.is_nil(input.get_text())
    end)
 end)

 describe("set_text", function()
    -- doc/input_api.md, "Live changes": replace
    -- content, cursor to end.
    it('replaces content and jumps to the end',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        input.set_text('worldly')
        assert.same({ 'worldly' }, F.widget:get_text())
        local l, c = input.get_cursor()
        assert.same(1, l)
        assert.same(8, c) -- 'worldly' end (len 7 + 1)
      end)

    -- doc/input_api.md, "The input widget — showing it and
    -- changing it": the same "string or list of line strings"
    -- shape reaches the live surface, so a newline splits here
    -- too rather than leaving the old content standing.
    it('splits a multi-line string into lines',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        input.set_text('a\nb')
        assert.same({ 'a', 'b' }, F.widget:get_text())
        local l, c = input.get_cursor()
        assert.same(2, l)
        assert.same(2, c)
      end)

    -- The list spelling of that same shape splits identically.
    -- The cursor is the reason: unsplit, the element would be
    -- one line three characters long and the caret could sit
    -- past the newline, so the two spellings would disagree
    -- about where the content ends.
    it('splits a multi-line list element into lines',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        input.set_text({ 'a\nb' })
        assert.same({ 'a', 'b' }, F.widget:get_text())
        local l, c = input.get_cursor()
        assert.same(2, l)
        assert.same(2, c)
      end)

    -- A list element that is not a string is a STRUCTURE error,
    -- not a spelling of the content shape, so it is refused at
    -- the boundary rather than normalised (D-CONTENT-NORM's
    -- tolerance boundary; the check follows checked_cursor,
    -- doc/development/technical_debt/input.md, "set_text
    -- answers a malformed content element three different
    -- ways"). One message for every bad element type: before
    -- this, a number was silently dropped, a list of only
    -- numbers wiped the content, and a boolean raised from
    -- inside utf8.len.
    describe("refuses a non-string element", function()
      -- The last three are the ones a walk with ipairs lets
      -- through: it stops at a hole and never sees a
      -- non-integer key, so each of these would slip past it
      -- and lose content downstream without a word.
      local bad = {
        ['a number'] = { 'a', 42 },
        ['only a number'] = { 42 },
        ['a boolean'] = { 'a', true },
        ['a nested table'] = { 'a', { 'b' } },
        ['a hole'] = { [1] = 'a', [3] = 'b' },
        ['a hole hiding a number'] = { [1] = 'a', [3] = 42 },
        ['keys that are not indices'] = { foo = 'bar' },
      }
      for label, value in pairs(bad) do
        it('raises on ' .. label .. ', naming set_text',
          function()
            local input = F.compy_input()
            input.show({ text = 'kept' })
            local ok, err = pcall(input.set_text, value)
            assert.is_false(ok)
            assert.matches('compy%.input%.set_text', err)
            assert.matches('list of line strings', err)
            -- refusal leaves the content alone
            assert.same({ 'kept' }, F.widget:get_text())
          end)
      end

      it('raises from show too, naming show', function()
        local input = F.compy_input()
        local ok, err =
          pcall(input.show, { text = { 'a', 42 } })
        assert.is_false(ok)
        assert.matches('compy%.input%.show', err)
        assert.matches('list of line strings', err)
      end)

      -- The error level is the whole reason api_set_text and
      -- api_set_cursor are lifted out of the surface table, and
      -- nothing tested it: changing 4 to 3 left the suite
      -- green, so an edit that interposes a frame would point
      -- every one of these messages at the framework's file.
      it('blames the caller line, not the framework',
        function()
          local input = F.compy_input()
          input.show({ text = 'kept' })
          local ld = loadstring or load
          local call = ld(
            'return function(i) i.set_text({ 1 }) end',
            '@/proj/main.lua')()
          local _, err = pcall(call, input)
          assert.matches('/proj/main%.lua:1:', err)
        end)
    end)

    -- D-CFG-BOUNDARY as amended 2026-09-07: text given is the
    -- content, text ABSENT leaves the content alone, and false
    -- is the uniform unset — so `text = false` is the same
    -- call as no text at all, and the draft survives it. The
    -- explicit fresh start is `text = ''`, which is given
    -- rather than unset; the case below is its pair.
    it('show{text = false} keeps what was there', function()
      local input = F.compy_input()
      input.show({ text = 'previous' })
      input.hide()
      input.show({ text = false })
      assert.same({ 'previous' }, F.widget:get_text())
    end)

    it("show{text = ''} is the explicit empty", function()
      local input = F.compy_input()
      input.show({ text = 'previous' })
      input.hide()
      input.show({ text = '' })
      assert.same({ '' }, F.widget:get_text())
    end)

    describe("with keep_cursor", function()
    -- doc/input_api.md, "Live changes": keep_cursor
    -- preserves position (clamped).
      -- activate_project: types across the text swap, so the
      -- project route has to be up to deliver it.
      it('preserves the cursor',
        function()
          local input = F.activate_project()
          input.show({ text = 'hello' })
          input.set_cursor(1, 3)
          input.set_text('world', true)
          local l, c = input.get_cursor()
          assert.same(1, l)
          assert.same(3, c)
          -- Seated for real, across the text swap: typing lands
          -- at the caret, which sits between 'o' and 'r' (caret
          -- positions, doc/input_api.md, "Live changes").
          F.session.type('X')
          assert.same({ 'woXrld' }, F.widget:get_text())
        end)

      it('clamps when text shrinks',
        function()
          local input = F.compy_input()
          input.show({ text = 'hello' })
          input.set_cursor(1, 5)
          input.set_text('xy', true)
          local _, c = input.get_cursor()
          assert.same(3, c) -- 'xy' end (len 2 + 1)
      end)
    end) 

    -- doc/development/internals/user_input.md, "Cursor
    -- manipulation and \"reset\"": the view reflects the
    -- change WITHOUT a re-show
    -- (the widget handle is not re-published; the widget's
    -- own view render fires via the controller's update_view).
    it('updates the view without a re-show',
      function()
        local input = F.compy_input()
        input.show({ text = 'hello' })
        local handle = love.state.user_input
        local renders = 0
        local orig = F.widget.view.render
        F.widget.view.render =
            function(...) renders = renders + 1 end
        input.set_text('again')
        F.widget.view.render = orig
        assert.equal(handle, love.state.user_input)
        assert.is_true(renders > 0)
      end)

    -- doc/input_api.md, "Live changes": hidden set_text
    -- no-ops and warns.
    it('while hidden warns and no-ops', function()
      local input = F.compy_input()
      local warned = 0
      local ow = Log.warn
      Log.warn = function() warned = warned + 1 end
      input.set_text('nope')
      Log.warn = ow
      assert.equal(1, warned)
      assert.is_true(F.widget:is_empty())
    end)
  end)

    -- doc/development/decisions/input.md, D-FROZEN-SHELL (what
    -- a project may assign): the four callables are not among
    -- them, so the frozen surface raises loudly rather than
    -- swallowing the write.
    it('assigning the cursor/text callables raises',
      function()
        local input = F.compy_input()
        assert.has_error(function()
          input.get_cursor = function() end
        end)
        assert.has_error(function()
          input.set_cursor = function() end
        end)
        assert.has_error(function()
          input.set_text = function() end
        end)
        assert.has_error(function()
          input.get_text = function() end
        end)
      end)
end)
