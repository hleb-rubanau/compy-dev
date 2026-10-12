# turtle

<!-- authored By LLM; human-approved NOT YET -->

**Turtle graphics interpreter** driven by typed commands and keyboard input.

## Architecture

Multi-file: `main.lua` (main loop, input wiring), `action.lua` (command table), `drawing.lua` (rendering: background, turtle icon, trail, debug overlay).

Overrides `love.draw`, `love.update`, `love.keypressed`, `love.keyreleased`.

## Input pattern

Dual input: typed commands via `compy.input.*` **(supported since 1.0.0-rc20260712)**, and direct keyboard actions. Turtle is the **auto-hiding** shape rather than the continuous session the other examples use: nothing is shown at load, `i` shows the widget, and `hide_on_submit` hides it on every successful submit — so each command gets a fresh, empty one. It is a **mode, not a one-off**: set once at the `show`, in force for every submit after it.

Turtle also keeps its keyboard on `love.keypressed`/`love.keyreleased` **on purpose**. The framework captures a project's own `love.*` keyboard functions and runs them as hooks, and this is the example that demonstrates that path — its keyboard handlers would behave identically written as `compy.input.hooks.*`. Keeping one example on the captured path is what makes the path visible at all.

```lua
-- The hide is the widget's: `hide_on_submit` at the show below.
-- after_submit only re-arms the echo guard for the next open.
compy.input.callbacks.after_submit = arm_echo_guard

function love.keyreleased(key)
  -- Open only when it is closed, and consume `i` only then: the hook
  -- runs BEFORE the widget, so without the guard every `i` typed into
  -- the widget would re-trigger show (which warns and no-ops).
  if key == "i" and not compy.input.is_shown() then
    compy.input.show{
      prompt = "TURTLE",
      hide_on_submit = true,
      on_text_entered = function(text)
        eval(text)
      end,
    }
    return true
  end
end
```

`eval(input)` looks up `actions[input]` and calls the function if found. Actions are defined in `action.lua` as a table mapping strings to closures. Typed input is thus a command dispatcher; the submit callback passes it the first submitted line.

"Re-arm" was the pre-feature vocabulary: because submit used to hide the widget, a project that wanted another line had to show it again. That is reversed now — the widget stays shown after submit unless a flag says otherwise, so a project that wants it hidden after every command **asks for that**: `hide_on_submit` is a mode, set once at the `show`, and it hides the widget on each successful submit until something passes `hide_on_submit = false`. It is not a one-off, and calling it one is the vocabulary that change retired (`../../decisions/input.md`, D-LIFECYCLE-FLAGS, which superseded D-AUTO-HIDE and kept its reasoning: *"`oneshot` names a single occurrence while this is a standing mode"*). What is left for turtle's `after_submit` is the echo guard alone. And yes: the missing hide is exactly why typed commands used to pile up in the widget (report A2, "input is not cleared after Enter") — a widget that never hid kept the previous command.

`love.keyreleased`: `i` shows the widget when it is not already shown, and consumes the key only in that case; while the widget is shown, `i` belongs to it. `shift+r`, which resets the turtle position, is on `love.keypressed` and asks `Key` for the modifier.

That guard is about *later* `i`s. The **first** `i` is a separate problem: LÖVE delivers a `keypressed` and a `textinput` for it in no guaranteed order, so the trigger's own echo can land in the widget it just showed. `arm_echo_guard` handles it — a one-shot `compy.input.shortcuts.textinput["i"]` that consumes the echo and unregisters itself, re-armed by `after_submit`, which now runs **after** the hide rather than before it and is armed for the next opening either way ([Compy Input API](../../../input_api.md), "Opening the input widget from a key"). Two guards, one line apart, for two different problems.

See [Compy Input API](../../../input_api.md) for the general usage pattern. The old `r = user_input()` / `input_text(...)` polling API is **(deprecated, removed in 1.0.0-rc20260712)**.

## Drawing

`drawing.lua` contains `drawBackground()` (clears to dark), `drawTurtle(tx, ty)` (draws a triangle pointing in the turtle's current direction), `drawHelp()`, and `drawDebuginfo()`. The turtle trail is drawn to the virtual canvas via `gfx.*` calls in the action functions — so trails persist across frames without a redraw loop.

## Points of attention

- Each command is one showing of the widget: `i` shows it, `hide_on_submit` hides it on submit, and the player presses `i` again for the next command. **The hide is the widget's, not the callback's** — `after_submit` re-arms the echo guard and nothing else (`main.lua`, the `hide_on_submit = true` at the `show` and `after_submit = arm_echo_guard` above it). The guard on `compy.input.is_shown()` is what keeps the `i` inside a typed word from re-triggering `show`; the one-shot textinput shortcut — genuinely one-shot, it unregisters itself — is what keeps the triggering `i` out of the widget. Hiding it without the re-arm would let the next `show` take the echo.
- `debug_color` is set in `love.update` based on turtle position — this modifies a global used by `drawDebuginfo`. The debug overlay is toggled by `space`.

## Files

`src/examples/turtle/` — main.lua, action.lua, drawing.lua
