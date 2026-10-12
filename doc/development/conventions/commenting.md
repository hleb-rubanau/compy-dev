# Commenting Conventions

<!-- authored By LLM; human-approved NOT YET -->

> Suggested conventions — not fully fixed; they evolve with experience.
> Formatting mechanics (own line, never inline; the 64-char limit) live in
> [`code.md`](code.md) and still apply; this doc governs **what a comment may
> contain**.

**Meta-rule: a comment should not exist if it does not carry information the code
cannot.** Everything below is that rule made checkable.

---

## The gate — apply to every comment you write, keep, or review

Ask in order; the first "yes" decides.

1. **Is it derivable from the code as it stands?** → delete it.
2. **Would a better name carry it?** → rename the function, variable or test,
   then delete it. A comment is not a repair for a name.
3. **Does it carry one of the four payloads below?** → keep it, at minimal
   viable size.
4. Otherwise → delete it.

---

## The four payloads — the only things worth a comment

1. **Intent or constraint** not obvious from the code and not expressible through
   naming: why this order, why this bound, what breaks if it changes.
2. **Non-local context** — a concept, contract or decision that lives elsewhere
   (another module, a design decision, a doc section). The comment carries the
   pointer **plus the one thing the reader needs here**; it does not reproduce
   what it points at.
3. **Availability** — `supported since <version>`, `deprecated since <version>`.
4. **A registered defect** — a `DEBT:` marker on a defect that is recorded in the
   technical-debt register and deliberately not fixed. It names what is wrong and
   cites the entry by section; by existing it says *known, left alone on purpose*.

---

## Size

- **Minimal viable, never below readability.** Prefer a clause to a sentence, a
  sentence to a paragraph.
- **A comment as long as or longer than the code it describes is a symptom, not a
  style.** Either the code cannot express itself (fix the code) or it is doing too
  much (split it). Where the code is genuinely irreducible — a platform quirk, a
  numeric tolerance — one line saying so is the fix.
- **No literary prose.** No restating a point in a second phrasing, no
  scene-setting, no rhetorical question answered by itself.

---

## What a comment must not do

- **Say what the code does *not* do.** An absence is waste — the code already
  says it, and more reliably. A *prohibition* is a payload: *"X must never be
  checked here"* is a constraint on every future edit, which the code cannot state
  at all. Write the rule, not the gap.
- **Narrate history** — "this used to…", "we removed…". Git holds history.
- **Restate the identifier in prose.** `-- the handler that handles the event`
  next to `handle_event` is noise.
- **Comment on itself** — "the following section explains…", "note that…".

---

## A reference is not an annotation

A comment reduced to a bare reference id or `-- see input_api.md, "Held keys"`
has been deleted, not compacted: it says something governs this code without
saying **what**, so the only way to learn is to leave the file.

**Every citation carries at least a clause of its own** — the claim, constraint
or reason that applies *here*. The reference is where the argument lives for
whoever digs deeper; the clause is what makes digging optional.

```lua
-- BAD: an index entry. What is true here?
-- (decisions/input.md, D-EXACT-RESERVE)
local reservation = RESERVED.keypressed[combo_string(k)]

-- GOOD: the claim, then where it is argued.
-- A reservation matches its modifier set exactly, so an
-- unnamed modifier misses (decisions/input.md, D-EXACT-RESERVE).
local reservation = RESERVED.keypressed[combo_string(k)]
```

One clause, not a précis: if the comment is long enough to argue the point, the
argument belongs in the doc and the comment belongs shorter.

---

## Citations stay resolvable

- Cite a **canonical doc** — a durable path, never a scratch/working-tree path
  that is deleted when a feature lands.
- Cite a **named section**, never "paragraph 3" or a line number.
- When you rename or remove a heading, **grep the source tree for the old name**.
  A citation that no longer resolves is worse than none, because it still reads as
  authoritative.
- **Never write an unreachable link from inside a separate example repository.**
  `src/examples/*` are their own repos with their own remotes; a `doc/…` path
  cannot be followed from a tree that does not contain it. Where such a comment
  must reference a platform contract, **name the guide and its section** in words
  (searchable) rather than as a path (a dead link) — and prefer saying the thing
  in place, briefly.
