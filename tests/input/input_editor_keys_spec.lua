-- Availability: the contract predates this feature — it is
-- @dsent's, authorized on UX grounds, and was retrofitted
-- into doc/development/decisions/input.md, D-EDITOR-KEYS on
-- 2026-09-06. What is new here is the net under it.

-- THE REGRESSION NET FOR THE EDITOR'S KEY CONTRACT, and it
-- pins what the tree DOES rather than what the contract says
-- it should. Our tree violates the bare-Escape row today, so
-- a case written against the contract would be red on arrival
-- and would read as a failure rather than as a baseline.
--
-- Every case the contract says must change carries a `FLIP:`
-- comment naming the decision that inverts it. A FLIP case
-- going red is evidence that change landed; a case going red
-- anywhere else is the regression this file exists to catch.
--
-- Cases marked `(w/o confirmation)` pin a KNOWN DEFECT at the
-- behaviour the release knowingly ships — see
-- doc/development/decisions/input.md, D-EDITOR-KEYS statement
-- 6, and doc/development/technical_debt/input.md,
-- T-EXITS-BYPASS-GUARD for the fix that is recommended and
-- not scheduled. They are pinned rather than left open so the
-- exits are inside the net; the marker is what stops a green
-- test from reading as a specification.
--
-- Every case drives the FULL ROUTE (F.session), not
-- EditorController:keypressed directly: the contract's
-- bare-Escape row binds what happens AFTER routing, and the
-- rest of the suite's Escape coverage drives the controller.
-- The states the editor already claims — an error message, a
-- confirmation dialog, search — are pinned by the imported
-- tests/editor/editor_spec.lua and are cited rather than
-- duplicated here.

local F  = require('tests.helpers.input_fixture')
require('tests.helpers.codesnippets')

describe('editor key contract #input', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)

  local ed, saved

  --- Open a file in the real editor, recording every write.
  local function open_file()
    saved = {}
    local body = mock_func_snippet('one')
    F.cc.editor:open('main.lua', body .. '\n',
      function(content)
        saved[#saved + 1] = string.unlines(content)
        return true
      end)
    return F.cc.editor
  end

  before_each(function()
    F.reset()
    love.state.app_state = 'editor'
    -- Entering reorder or search saves the clipboard state
    -- (EditorController:set_mode -> save_state), and the
    -- input fixture's love has no `system` — the same stub
    -- editor_spec.lua sets per case.
    love.system = {
      getClipboardText = function() return '' end,
      setClipboardText = function() end,
    }
    ed = open_file()
  end)

  --- Load the selected block and modify it: Enter opens it
  --- (the rework's spec 2.2), and the edit makes it dirty.
  local function open_dirty_block()
    F.session.press('return')
    ed.input:set_text(
      string.lines(mock_func_snippet('renamed')))
  end

  describe('bare Escape', function()
    -- D-EDITOR-KEYS row 2: bare Escape does NOTHING in
    -- navigation and in editing. The key is unclaimed in
    -- _normal_mode_keys and falls through to the widget, whose
    -- cancel does nothing because the editor's widget seats no
    -- lifecycle flags (doc/development/decisions/input.md,
    -- D-LIFECYCLE-FLAGS, statement 3). Navigation's half is
    -- pinned next door, in input_widget_callbacks_spec.lua,
    -- "editor Escape falls through to the widget"; this is
    -- the editing half, and it is the one that cost a user
    -- something.

    -- FLIPPED as its FLIP comment said it would be: the case
    -- asserted the loss until D-LIFECYCLE-FLAGS landed, and
    -- now asserts the contract. It is the breaking test for
    -- the edit-mode data loss (that decision's acceptance
    -- criterion 2), so it asserts the block's CONTENT rather
    -- than which callback fired — the pins that assert order
    -- stayed green all the way through the defect.
    it('leaves the open block untouched', function()
      open_dirty_block()
      -- A COPY, not the model's own table: comparing the
      -- widget's text against a reference into it would pass
      -- whatever the cancel did to it.
      local block = string.lines(mock_func_snippet('renamed'))
      assert.same(block, ed.input:get_text())

      F.session.press('escape')

      assert.same(block, ed.input:get_text())
      assert.same('edit', ed:get_mode())
    end)

    -- The fourth of the four states the contract says bare
    -- Escape IS claimed in, and the only one the suite did
    -- not hold: editor_spec.lua presses it at a reorder edge
    -- as setup and asserts nothing about it. Contract-
    -- conforming today, so no FLIP — it must survive
    -- D-LIFECYCLE-FLAGS untouched, which is what makes it
    -- worth pinning before that lands.
    it('cancels a block reorder', function()
      F.session.press('lctrl')
      F.session.press('m')
      assert.same('reorder', ed:get_mode())

      F.session.press('escape')

      assert.same('nav', ed:get_mode())
    end)
  end)

  describe('the two unguarded exits', function()
    -- D-EDITOR-KEYS statement 6. Both leave the editor
    -- through ConsoleController:finish_edit, which stores
    -- the clipboard and drops the buffers with no acceptance
    -- step, so an open changed block is lost silently. This
    -- branch did not create these exits — only moved the
    -- layer they sit at, which is why they are in our
    -- contract at all.
    local left, ran, orig_finish, orig_run

    before_each(function()
      left, ran = false, false
      orig_finish = F.cc.finish_edit
      orig_run = F.cc.run_project
      F.cc.finish_edit = function() left = true end
      F.cc.run_project = function() ran = true end
    end)

    after_each(function()
      F.cc.finish_edit = orig_finish
      F.cc.run_project = orig_run
    end)

    it('Ctrl+Shift+S leaves (w/o confirmation)', function()
      open_dirty_block()

      F.session.press('lctrl')
      F.session.press('lshift')
      F.session.press('s')

      assert.is_true(left)
      --- the edit reached no write on the way out
      assert.same({}, saved)
    end)

    it('Ctrl+T leaves and runs (w/o confirmation)', function()
      open_dirty_block()

      F.session.press('lctrl')
      F.session.press('t')

      assert.is_true(left)
      assert.is_true(ran)
      assert.same({}, saved)
    end)
  end)
end)
