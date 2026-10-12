---
description: Short how-to for project authors — ask the user a question, or run your own input widget and handle keys and clicks
status: active
audience: project author
authored: llm
reviewed: none
---

# Input in your project — how-to

Two ways to get input from the user. Pick by what your program needs:

| You want to… | Use | Mental model |
|---|---|---|
| ask a question and get an answer | **the basic API** — `compy.ask` and friends | *a question*: ask it, the answer comes back |
| keep an input line on screen, react to keys and clicks, decide what Enter and Escape do | **the advanced API** — `compy.input.*` | *a widget you show, and a chain every event walks* |

Both drive the same input widget, so starting with the basic API costs you
nothing later. The full reference is [`input_api.md`](input_api.md).

---

## The basic API — a question

**The model:** you ask; the user answers or gives up; your function is called
once with the result. Nothing to set up and nothing to tear down.

```lua
compy.on_answer = function(text)
  if text then
    print("hello, " .. text)
  else
    print("never mind")
  end
end

compy.ask("Your name?")
```

- **Enter** submits: `on_answer` gets the typed text, and the question goes
  away.
- **Escape** gives up: `on_answer` gets **`nil`**. That is how you tell
  *answered* from *abandoned*.
- **Enter on an empty line does nothing.** The question stays open. If your
  program needs a way out, the user has Escape, or you can ask for a word
  (`"r to restart"`) instead of a bare Enter.

**Asking again** is just another `ask`, and it is fine to do it from inside
`on_answer`:

```lua
local secret = math.random(1, 100)

compy.on_answer = function(text)
  if not text then return print("bye") end
  local n = tonumber(text)
  if n == secret then return print("yes!") end
  if not n then
    print("a number, please")
  elseif n < secret then
    print("higher")
  else
    print("lower")
  end
  compy.ask("Guess:")
end

compy.ask("Guess a number from 1 to 100:")
```

**Reacting to keys while a question is open:** `compy.on_key`. Return `true`
to claim the key. Return nothing and it edits the answer as usual.

```lua
compy.on_key = function(key)
  if key == "f1" then show_help(); return true end
end
```

Ordinary characters and bare modifier keys are not reported here; they are
just typing.

**Taking a question back:** `compy.unask()`. The question closes and
`on_answer` is **not** called, because nobody answered.

**One rule:** `compy.ask` raises if your program also defines
`love.keypressed` or `compy.input.hooks.keypressed`, because a question needs
that channel. If you need both, use the advanced API.

`ask` also takes optional arguments: `compy.ask(prompt, highlighter, text,
cursor)` sets a highlighter, initial text, and where the cursor starts.

---

## The advanced API — a widget, and a chain

Two independent parts. Use either one alone, or both:

1. **The widget**: an input line you show, with callbacks it calls.
2. **The chain**: how every key, click and touch reaches your code.

### The widget

**The model:** the widget is **one object for the whole run**. You show it,
and it stays until you hide it. Hiding and showing never lose anything: text,
label and callbacks are all still there next time.

```lua
compy.input.show{
  prompt = "say something:",
  on_text_entered = function(text)
    print("you said: " .. text)
  end,
}
```

That is a complete continuous prompt. Out of the box:

| When the user… | the widget… |
|---|---|
| presses **Enter** with text | calls `on_text_entered(text)`, empties itself, **stays shown** |
| presses **Enter** on an empty line | does nothing |
| presses **Escape** | **does nothing** — until you choose an outcome |

To change that, set the **lifecycle flags**. They persist until you change
them:

| flag | effect |
|---|---|
| `hide_on_submit = true` | hide after a successful Enter: the "ask one question" form |
| `clear_on_submit = false` | keep the text after Enter (on by default) |
| `hide_on_cancel = true` | Escape hides the widget and **keeps** the text |
| `clear_on_cancel = true` | Escape also empties it |

```lua
compy.input.show{
  prompt = "Your name?",
  hide_on_submit = true,
  hide_on_cancel = true,
  on_text_entered = function(text) greet(text) end,
}
```

Prefer `hide_on_cancel` to `clear_on_cancel`: Escape usually means *"get me
back"*, not *"throw my typing away"*.

**Other calls you will want:**

- `compy.input.hide()`, then a later `compy.input.show()`, brings it back as
  the user left it.
- `compy.input.show{ text = '' }` brings it back empty.
- `compy.input.is_shown()` tells you whether it is on screen.
- `compy.input.get_text()` / `set_text(text)` / `clear()` read and change the
  text.
- `compy.input.configure{...}` changes the label, callbacks or flags without
  showing.

**Checking what was typed:** give the widget a `validator`. A rejected entry
stays in the widget with the error shown, and `on_text_entered` is not
called.

```lua
local natural = function(line)
  if line:match("^%d+$") then return true end
  return false, Error("Expected a natural number", 1)
end

compy.input.show{
  prompt = "How many?",
  validator = LineValidators(natural),
  on_text_entered = function(text) count = tonumber(text) end,
}
```

For Lua code entry, `LuaHighlighter` and `LuaSyntaxValidator` go in
`highlighter` and `validator`.

### The chain

**The model:** every input event is offered to up to three consumers, in
order, and **the first one that claims it wins**:

```
  key / click / touch
    │
    ▼
  ① shortcut  compy.input.shortcuts.<channel>[combo]   one exact combo
    │           returned true → done
    ▼
  ② hook      compy.input.hooks.<channel>              the whole channel
    │           returned true → done
    ▼
  ③ widget    if it is shown, it takes the event
```

**Claim by returning `true`.** Return nothing and the event goes on down.

**A hook for a whole channel:**

```lua
compy.input.hooks.keypressed = function(key)
  if key == "left"  then move(-1); return true end
  if key == "right" then move(1);  return true end
end
```

**A shortcut for one combo:**

```lua
compy.input.shortcuts.keypressed["ctrl+s"] = function()
  save_game()
  return true
end
```

**Clicks** are hooks too:

```lua
compy.input.hooks.singleclick = function(x, y) place(x, y) end
compy.input.hooks.doubleclick = function(x, y) remove(x, y) end
```

`mousepressed`, `mousereleased`, `mousemoved`, `wheelmoved` and the `touch…`
channels work the same way, with LÖVE's own arguments.

### Two things that catch people out

**1. `love.keypressed` takes every key.** Plain LÖVE handlers still work: a
`function love.keypressed(key)` becomes your hook automatically. But it
**claims every event on its channel**, whatever it returns, just as it owned
the key in plain LÖVE. With no widget that is exactly right. **With a widget
on screen, the user cannot type, not even Enter.** If you show the widget,
write `compy.input.hooks.keypressed` instead, and return `true` only for the
keys you mean to take.

**2. Your hooks run before the widget.** While the widget is shown, every key
the user types reaches your hook first. A game hook that moves on `"r"` will
move while the user types `"restart"`. Make the hook stand aside while the
widget is up:

```lua
compy.input.hooks.keypressed = function(key)
  -- let the widget have every key while it is up
  if compy.input.is_shown() then return end
  -- your game keys
end
```

Some combos belong to the platform, such as Ctrl+Esc to stop the run. Your
binding for one still runs, but the platform acts too. The list is in the
reference, under *"Combos the framework keeps"*.

---

## Where to go next

The reference, [`input_api.md`](input_api.md), has the full details:

- every `show` key, and what `false` does → *"The input widget —
  showing it and changing it"*
- the exact submit and cancel order, and the `before_*` / `after_*` callbacks
  → *"What the widget tells you — callbacks"*
- held keys, modifier classes (`"alt+*"`), and picking between a hook, a
  shortcut and state → *"Inbound events — shortcuts and hooks"*
- putting device state back when a run stops → *"Stop hook —
  `compy.before_exit`"*
- moving off the old `user_input()` / `input_text()` globals → *"Migration
  from the legacy globals"*
