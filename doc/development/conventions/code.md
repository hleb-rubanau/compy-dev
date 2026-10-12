# Code Conventions

<!-- authored By LLM; human-approved NOT YET -->

> These conventions are not fully fixed — they evolve with experience. Some are unique to this project by design.
> Further discussion: https://github.com/compy-toys/compy/issues/54

---

## Formatting

Formatting is handled automatically by the metalua pretty-printer. No manual formatting rules are enforced — the built-in Compy editor auto-reformats on save. **Published examples must be idempotent under the editor** (run the editor over the code before publishing; it should produce no changes).

### Style examples

```lua
-- if/for/function: `end` on the same line as the last statement in the block
if condition then
  ...end

for iteration do
  ...end

function outer(args)
  local inner = function(args)
    ...  end
end

-- empty table: spaces inside braces
empty = { }

-- array/table: each element on its own line
array = {
  1,
  2,
  3
}

-- all comments on their own line (not inline)

-- at most one blank line between non-blank lines
```

---

## Structural Limits

| Rule | Limit |
|---|---|
| Line length | 64 characters (fits the Compy screen) |
| Function length | 14 lines (16 tolerated — see below) |
| Parameters per function | 4 |
| Nesting depth | 4 levels |

When a limit is approached, redesign — don't raise the limit.

**The one tolerance.** A function body may run to **16 lines** when the only
alternative is extracting a helper whose sole job is to satisfy the limit. A
helper that exists for the counter rather than the reader buys nothing — it adds
a name, a call site and a doc-comment to save two lines. Before using the
tolerance, check the cheaper fix first: comment boilerplate inside the body
counts toward nothing and is usually where the overflow came from. (The case
that produced this allowance needed neither — trimming the comments took the
body to eight lines.)

---

## Code Style

**Extract compound conditions to named locals:**
```lua
-- avoid
if a and b or c then end

-- prefer
local cond = a and b or c
if cond then end
```

**Do not use local variables outside their block.** A local should be scoped as tightly as possible.

**File = console equivalence.** Code in a `.lua` file and the same code typed into the Compy console must have identical effect. This guides how modules and scripts are structured.

**No invented special cases (KISS, DRY).** Solve the requirement, not a
generalisation of it. A rule that applies to one case is a special case, and a
special case the system did not ask for is a defect however small and however
principled it reads — it is a second rule to learn, to document, and to keep
true. Signs you are inventing one: a sentinel return value that only one caller
produces; a branch whose other arm nothing exercises; an exception clause
appended to a decision that was uniform before. The minimum that satisfies the
requirement is the answer. When a fix genuinely needs a new mechanism, say so and
get it agreed rather than shipping it inside a fix that was approved without it.
```lua
-- wrong: an unbound channel needs a callable method, so the
-- method was given a decline protocol the chain had no other use for
function Widget:singleclick() return false end
if widget:is_shown() then return widget[event](widget, ...) ~= false end

-- right
function Widget:singleclick() end
if widget:is_shown() then widget[event](widget, ...); return true end
```

**Don't over-fix.** Solve the request and its blockers, no more. Debt you notice
in passing is **reported, not fixed on the spot** — it goes to the technical-debt
register (`../technical_debt/README.md`), so the change stays scoped and the debt
stays visible instead of vanishing into an unrelated commit.

---

## Standard Abbreviations

```lua
local gfx = love.graphics
local sfx = compy.audio
```
