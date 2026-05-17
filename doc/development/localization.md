# Localization Approach — Design Guide
## LÖVE2D / Android / Early-Stage Educational Games

---

## Context and Constraints

**Platform:** LÖVE2D on Android.

**Product:** Simple educational games for children aged 4–6 — their first or near-first experience with a computer or tablet. Games include keyboard-oriented exercises ("Find the key", "Type the sequence").

**Scale:** ~10–20 UI messages per game. No thousands of strings; no complex pluralization rules.

**Audience assumptions:**
- Children do not configure language themselves. Language is set by a teacher or parent at install/setup time and does not change during play.
- Devices are likely shared or school-issued and may have both English and Russian keyboard layouts available (Russian IME on Android is very common in the target demographic).
- The game must be tolerant of mid-session keyboard language switches — whether accidental (child taps the IME toggle) or intentional.

**Supported locales, now:** English (default) and Russian.

**Input framework note:** The project uses its own input-handling layer on top of LÖVE2D callbacks. Recommendations below describe *what the framework must do at the principle level*, not which LÖVE2D functions to call directly.

---

## A) Message Translation

### Format: Lua tables aligned with ICU/gettext conventions

Use one Lua file per locale, returning a flat key→string table. Keys should follow the dotted-namespace convention used by `lua-i18n` and similar libraries, so a future migration to a proper i18n library requires only a file-format change, not a key-naming overhaul.

**Reference for key naming and structure:** follow the conventions described in the [ICU Message Format](https://unicode-org.github.io/icu/userguide/format_parse/messages/) and as implemented by `lua-i18n` (kikito). You don't need to implement all of it — just model your key names and interpolation placeholders after it.

**`lang/en.lua`**
```lua
return {
  ["exercise.find_key.prompt"]  = "Find this key: {key}",
  ["exercise.type_seq.prompt"]  = "Type the sequence:",
  ["feedback.correct"]          = "Correct!",
  ["feedback.try_again"]        = "Try again",
  ["input.wrong_script"]        = "Please use the {script} keyboard",
}
```

**`lang/ru.lua`**
```lua
return {
  ["exercise.find_key.prompt"]  = "Найди клавишу: {key}",
  ["exercise.type_seq.prompt"]  = "Введи последовательность:",
  ["feedback.correct"]          = "Правильно!",
  ["feedback.try_again"]        = "Попробуй ещё раз",
  ["input.wrong_script"]        = "Пожалуйста, используй {script} клавиатуру",
}
```

Use `{placeholder}` style (not `%s`) — it is the convention in ICU/i18next/lua-i18n and is self-documenting.

**Minimal wrapper:**
```lua
local i18n = {}
local strings = {}

function i18n.load(lang)
  local ok, t = pcall(require, "lang." .. lang)
  strings = (ok and t) or require("lang.en")  -- always fall back to English
end

function i18n.t(key, vars)
  local s = strings[key] or key  -- key itself as last-resort fallback
  if vars then
    s = s:gsub("{(%w+)}", vars)
  end
  return s
end

return i18n
```

### When custom tables stop being sufficient

Migrate to a real i18n library (e.g. `lua-i18n`) when any of the following arise:

- **Pluralization** — "1 mistake" vs "3 mistakes"; Russian has three plural forms (one/few/many), which is painful to handle manually.
- **Gender agreement** — relevant for Russian and many other languages.
- **10+ locales** — managing fallback chains, missing-key reporting, and reload-on-change by hand becomes error-prone.
- **Translator workflow** — when non-developers need to edit strings (professional tools expect PO/XLIFF formats, not Lua files).

If you anticipate any of these within 6–12 months, set up `lua-i18n` from the start — the key naming convention above ensures a nearly mechanical migration.

---

## B) Language Configuration

### Android locale is not readable from LÖVE2D

There is no `love.getLocale()` API. Environment variables (`LANG`, `LC_ALL`) are unreliable inside the Android APK sandbox. Do not attempt auto-detection.

### Recommended approach: teacher/parent configures at setup, game persists the choice

The child never sees a language selector. Language is an administrative setting:

- During first launch (or via an explicit "settings" function accessible to adults), a teacher sets the language.
- The game writes the preference to its save directory and reads it on every subsequent launch.
- Default: English, if no preference has been saved.

```
First launch (no saved prefs)
  → game starts in English
  → teacher opens settings / setup screen
  → selects language → saved to disk
  → game reloads strings

Subsequent launches
  → read saved lang → load strings → start game
```

This model keeps the child-facing UI clean and puts configuration control where it belongs.

**Save format** (`save/prefs.lua`, written at runtime):
```lua
return { lang = "ru" }
```

---

## C) Input Handling — First-Principle Recommendations

> These describe what the input layer must handle. Implementation via LÖVE2D callbacks, your own framework, or a combination is left to the team.

### Principle 1: Distinguish character input from control input

Two fundamentally different event types flow from the keyboard:

- **Character events** — the Unicode code point(s) produced by a key press, after the OS and IME have processed the keystroke. This is what the user "typed."
- **Control events** — physical key actions that don't produce a character: Backspace, Enter, arrow keys, Delete.

**Never use physical key identity to identify characters.** A key labeled "А" on a Russian keyboard is the same physical key as "F" on an English QWERTY keyboard. Matching by key name or scancode for character exercises is always wrong across layouts.

### Principle 2: Accept the OS-composed character, don't reconstruct it

The OS (via Android IME) is responsible for converting keystrokes into Unicode characters, handling dead keys, combining characters, and IME composition. The input layer must receive this final composed character as a UTF-8 string and treat it as the atomic unit of input — it should not attempt to re-derive what character was typed from raw key events.

In LÖVE2D terms: the `textinput` callback delivers this character; `keypressed` delivers control events. Your framework should route these to separate handlers.

### Principle 3: Validate script, not just value

For exercises that require a specific script (Latin, Cyrillic), the input layer must check which Unicode block a character belongs to before accepting it. The exercise knows what script it expects; the input layer enforces it.

**Unicode block ranges (for validation logic):**

| Script | Range |
|---|---|
| Basic Latin (A–Z, a–z) | U+0041–U+005A, U+0061–U+007A |
| Cyrillic | U+0400–U+04FF |
| Latin Extended (accented chars) | U+00C0–U+024F |

```lua
-- Example utility (framework level):
local function scriptOf(char)
  local cp = utf8.codepoint(char)
  if cp >= 0x0041 and cp <= 0x007A then return "latin" end
  if cp >= 0x0400 and cp <= 0x04FF then return "cyrillic" end
  return "other"
end
```

An exercise declares its expected script. The input layer calls `scriptOf()` and either rejects the character silently, buffers it with a flag, or fires an `onWrongScript` event — whichever the exercise UI needs.

### Principle 4: Wrong script is a UX signal, not just a validation failure

Children aged 4–6 will not understand why their typing is being ignored. When the wrong script is detected:

- Provide immediate, gentle visual feedback ("Use the English keyboard" / "Используй русскую клавиатуру") in the game language.
- Do not fail the exercise silently — the child will be confused.
- Keep feedback non-alarming; this is a normal situation on bilingual devices.

The game cannot prevent keyboard language switches — Android controls the IME switcher. Design for tolerance, not prevention.

### Principle 5: String comparison is byte equality in UTF-8

When checking if typed input matches an expected answer, direct string equality (`==`) works correctly for fully composed UTF-8 strings. No special Unicode comparison is needed for Latin and Cyrillic, as long as both sides are NFC-normalized — which they will be if both come from the same source (OS keyboard output and your string literals in source files). No normalization library is needed at this stage.

For counting characters (e.g. "3 of 5 typed"), use UTF-8 character length, not byte length, since Cyrillic characters are 2 bytes each in UTF-8.

### Principle 6: IME composition phase

Some input methods (especially for CJK scripts, but also some Russian swipe keyboards) have a multi-step composition phase where the user is assembling a character before committing it. LÖVE2D exposes this via `love.textediting`. For Latin and Cyrillic exercises, this phase is irrelevant — characters commit immediately. No special handling is needed now. If non-trivial IME input is ever required, the input layer would need to track a "composing" state and only act on committed characters.

---

## D) Unicode and Fonts

### The default font problem

LÖVE2D's built-in default font (Bitstream Vera Sans, used in LÖVE 11.x) does not contain Cyrillic glyphs. Russian text displayed with this font produces rectangles ("tofu"). **Always bundle a font.**

### Recommendation: Bundle Noto Sans (Latin + Cyrillic subset)

Noto Sans covers Latin and Cyrillic fully in a single file (`NotoSans-Regular.ttf`, ~550 KB). It is free, open-source (OFL license), and bundleable in commercial products. This covers English, Russian, Ukrainian, Serbian in Latin script, Bulgarian, and most Eastern European scripts without any additional files.

**Serbian note:** Serbian uses both Cyrillic and Latin scripts depending on context. Noto Sans covers both; no separate font is needed.

Load it explicitly at startup — do not rely on the LÖVE version default:

```lua
-- load.lua or equivalent
Fonts = {
  ui   = love.graphics.newFont("assets/fonts/NotoSans-Regular.ttf", 20),
  body = love.graphics.newFont("assets/fonts/NotoSans-Regular.ttf", 16),
}
```

### UTF-8 string operations

Lua's `string` library is byte-based. For character-level operations, use the built-in `utf8` library (available in Lua 5.3+ / LÖVE 11+):

```lua
utf8.len(s)          -- character count (not bytes)
utf8.codepoint(s)    -- code point of first character
utf8.codes(s)        -- iterator over (position, codepoint) pairs
```

Direct `==` comparison and concatenation (`..`) work correctly on UTF-8 strings for answer checking and building output.

### Future: expanding beyond Latin and Cyrillic

If the product expands to Arabic, Hebrew (RTL scripts), or CJK languages, the following challenges arise that are non-trivial in LÖVE2D:

- **Right-to-left rendering** — LÖVE has no built-in BiDi support; Arabic/Hebrew would require a shaping library (e.g. HarfBuzz via FFI) or a custom text layout layer.
- **Font size** — Noto Sans CJK is ~20 MB; separate Noto Sans Arabic is ~300 KB. Font bundling strategy needs revisiting.
- **IME composition** — CJK input is fundamentally composition-based; the input layer described above would need rework.

These are real engineering investments. When entering a new script family, budget accordingly and evaluate whether LÖVE2D remains the right foundation.

---

## Summary

| Concern | Decision |
|---|---|
| **Message format** | Lua tables, dotted keys, `{placeholder}` interpolation — ICU-compatible naming |
| **When to switch to a real i18n lib** | Pluralization, gender, 10+ locales, or translator workflow |
| **Language setting** | Configured by teacher at setup; persisted to disk; default English |
| **Auto-detecting Android locale** | Not feasible; don't attempt it |
| **Character input** | Accept OS-composed UTF-8 character; never reconstruct from key events |
| **Control input** | Handle separately from character input (Backspace, Enter, etc.) |
| **Wrong-script input** | Detect by Unicode range; show gentle child-facing feedback; tolerate gracefully |
| **IME composition** | No handling needed for Latin/Cyrillic now; note for future CJK |
| **Font** | Bundle Noto Sans Regular (covers Latin + Cyrillic); ~550 KB; OFL license |
| **String comparison** | `==` is correct for UTF-8; use `utf8.len` for character counting |
| **Future scripts (Arabic, CJK)** | Significant engineering; evaluate platform suitability when the time comes |

---

## File Structure

```
your-game/
├── i18n.lua
├── lang/
│   ├── en.lua
│   └── ru.lua
├── assets/
│   └── fonts/
│       └── NotoSans-Regular.ttf
└── save/
    └── prefs.lua       -- written at runtime
```
