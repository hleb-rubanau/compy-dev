# Changelog

Protocol: `CURRENT_SCOPE` holds everything not yet released. When a version
ships, this section is emptied and its content moves down into a new
section named for that version. Released versions are listed below it,
newest first.

## CURRENT_SCOPE

A new project input API: one widget with a basic wrapper (`compy.ask`) and an
advanced surface (`compy.input`), a lifecycle the project configures, first-class
keyboard/mouse/touch shortcuts, and the removal of the legacy polling globals.
Project-author guide: `doc/input_api.md`.

> **Breaking, pre-1.0:** the legacy text-input globals are removed with no
> compatibility shim (see *Removed*). This is a `1.0.0-rc`, so the break is
> announced here rather than in the version number.

### Added

- **The basic API — a quick way to ask a question — `compy.ask`.** `compy.ask(prompt, …)` asks,
  `compy.on_answer(text)` receives the answer (or `nil` on Escape),
  `compy.on_key(...)`'s return value decides who consumes a key, and `compy.unask()`
  withdraws the question. A wrapper over the same widget — no second widget or event
  path.
- **The advanced surface — `compy.input`:** `show`, `hide`, `configure`, `clear`,
  `set_text`, `set_cursor`, `get_text`, `get_cursor`, `is_shown`, plus callbacks,
  hooks, shortcuts and `fn`. One `show` and a callback (`on_text_entered`) replace the
  poll-a-global-every-frame idiom. Its lifecycle is set by **four independent flags** —
  `clear_on_submit`, `hide_on_submit`, `clear_on_cancel`, `hide_on_cancel` — each a
  mode that persists until unset. Content-bearing callbacks receive one `\n`-joined
  string; `validator`/`highlighter` receive the lines.
- **New set of capabilities to manage input events: shortcuts, hooks, dispatching chain:** 
  keyboard/mouse/touch **shortcuts** by combo and
  per-event **hooks** (`compy.input.hooks`), plus per-binding **repeat/propagation
  control** (`compy.input.fn`) and **`compy.before_exit`** to restore device state
  before a run ends. Details in `doc/input_api.md`.

### Changed

- Colouring, the submit gate and the submit action are three independent, optional
  keys (`highlighter`, `validator`, `on_text_entered`) rather than a choice of function
  name (`input_text` / `input_code` / `validated_input`).
- Keyboard and text input are no longer blocked while the widget is shown — a project
  keeps receiving its own `love.*` events while the user types.
- A project's own `love.*` input handlers (`keypressed`, `textinput`, `mousepressed`,
  …) are **captured and driven by the input system** rather than served directly by
  LÖVE — they were not served directly before either; they now seed into the matching
  hook and join the unified dispatch chain.
- **`singleclick` / `doubleclick` are repositioned** as input channels
  (`compy.input.hooks.singleclick` / `.doubleclick`, replacing the preceding
  `compy.singleclick` / `compy.doubleclick` for the uniformity). 
- **The code editor opens with the first block selected, not the last.** Opening a
  file (or following a `require`) now starts editing at the first block rather than
  the last one.

### Removed

- **Polling user input is gone entirely.** The idiom of reading input by checking a
  global every frame is removed; use the new event-driven, asynchronous API, which
  shows/hides and manages the input widget through its own calls and callbacks.
- **Breaking: the legacy text-input globals**, with no shim — `input_text`,
  `input_code`, `validated_input`, `user_input` and `write_to_input`. `doc/input_api.md`
  (*"Migration from the legacy globals"*) maps each to its replacement.
- The four evaluator objects (`InputEvalText`, `InputEvalLua`, `ValidatedTextEval`,
  `LuaEditorEval`) are no longer reachable from a project; what a project needs is
  exported narrowly instead (`LuaHighlighter`, `LuaSyntaxValidator`, `LineValidators`).

### Fixed

- Multi-line string content now writes — `show{text = "a\nb"}` / `set_text("a\nb")`
  previously wrote nothing silently — and the two spellings of the text shape now agree.
- Non-text content is refused with a readable message that names the failing call.
- The error boundary no longer swallows crashes in a project's `love.update` or pointer
  handlers, and no longer drops callback arguments on non-LuaJIT (PUC 5.1) runtimes.
- Unconsumed project input no longer accumulates in the console while the console is
  not visible.
