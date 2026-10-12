---
description: Input subsystem debt — sorted ACTIVE / BACKLOG / RETIRED by release scope
status: active
audience: developer
authored: llm
reviewed: none
---

> REVIEW: drop everything resolved, actualize the list, and maybe make it a bit more comprehensive (less prose, more facts). ToC (list) at the beginning would also help
> REVIEW: absolutely no mentioning of particular commits is allowed, they will be reassembled for the PR

# Input subsystem

Keyboard/text/pointer routing, the console and project input controllers
(`src/controller/controller.lua`, `userInputController.lua`,
`projectInputController.lua`, `consoleController.lua`), and the project-facing
`compy.input` surface. Cross-reference: `internals/user_input.md`,
`../input_api.md`. "The input API" below means the `compy.input` surface
introduced in **1.0.0-rc20260712**.

Three sections below, in disposition order — not severity, not intent:
**ACTIVE** is debt still owed; **BACKLOG** is real, acknowledged debt
deliberately deferred; **RETIRED** is paid, or turned out not to be debt.
*(The #77 input-API release **shipped 2026-09-12**; the remaining `ACTIVE`
input debt is the post-release corrective tail, not a gate the shipped release
waited on.)*

---

## ACTIVE

The remaining input debt is documentation and vocabulary — nothing here changes `src/`. The live
entries are the `### ` headings between here and `## BACKLOG`. `BACKLOG` is full deliberately and
nothing there blocked the shipped release.

### T-RECALL-RECIPE-OMITS-COUPLING — the history-recall recipe omits the one thing that silently breaks it

**Found by a round-trip bugreport (2026-09-17):** a project author built up/down history on the
documented recipe and reported the arrows doing nothing in a single-line field. Investigated against
the de-facto edge, and **the recipe itself works** — reproduced end-to-end (single-line,
`on_limit_reached` seated by `show{}` config OR by direct assignment; submit → clear → up recalls the
sent line). What the recipe does not do is warn the author about the one framework behaviour that
silently defeats it.

- **Where:** `../input_api.md`, *"The widget's input history is its own, not yours to read"* — the
  recall recipe (keep your own list, drive with `set_text`, use `on_limit_reached` as the trigger).
- **State:** the recipe presents `on_limit_reached` as the guaranteed trigger, but it fires only if the
  keystroke reaches the widget. A project `love.keypressed`, a `compy.input.hooks.keypressed`, or an
  up/down `compy.input.shortcuts.keypressed` consumes the arrow first — and a **seeded** `love.keypressed`
  consumes *unconditionally* (`../decisions/input.md`, D-HOOKS-SEEDED). The drop is silent: no error, no
  warning. An author who handles keys the LÖVE-native way while following the recall recipe loses the
  arrows with no signal why. (The underlying coupling is the BACKLOG entry *"A truthy `hooks[event]`
  return silently disables `on_limit_reached`"*.)
- **Also unstated at the recipe site, both worth a line:** the single-line worry is a non-issue — a
  single-line field DOES fire `on_limit_reached('up'/'down', 'input')`; and `on_limit_reached` reaches
  the widget whether seated in `show{}`/`configure{}` or by assignment, because the project widget is
  built before the project's top-level code runs (`../decisions/input.md`, D-WIDGET-AT-BOOT).
- **The fix (documentation):** at the recall recipe, add the coupling warning (a `love.keypressed` /
  keypressed hook / up-down shortcut that consumes will silently swallow the arrows) and, briefly, the
  two clarifications above. Scoped to `../input_api.md`; no `src/` change.
- **Pays:** the *Revisit* obligation of the BACKLOG coupling entry (*"Note the coupling wherever
  `on_limit_reached` is documented for project authors"*).

## BACKLOG

### T-HISTORY-UNREACHABLE — no project-facing way to read, navigate or clear the input history (capability deferred; the limitation is documented)

**MOVED FROM `ACTIVE` TO `BACKLOG` 2026-09-09 (session89).** The entry was `ACTIVE`
for one reason: the release shipped a `clear_on_submit`-on default that writes every
submitted line into a store a project cannot read, so the guide had to say so.
That documentation is now paid — `../../input_api.md`, *"The widget's input
history is its own, not yours to read"*, in the `hide()`/`get_text` section, which
states that the history is the widget's own, that a project keeps its own list, and
that `on_limit_reached` is the trigger the console itself uses. With the limitation
documented, nothing release-blocking remains; what is left is a capability, and it
is deferred.

- **What is deferred:** a project-facing way to read, navigate or clear the
  widget's history. `src/model/input/userInputModel.lua` holds `history` (a
  `History`, sized from `cfg.input_history`) with `history_back` / `history_fwd` on
  the model and controller; the public surface reaches none of it.
- **Why `BACKLOG` and not `ACTIVE`: the provenance test** (owner rule, 2026-09-09).
  `ACTIVE` would require the capability to have been explicitly requested by a
  stakeholder in the attestations that formed the proposal block. It was not: the proposal
  block never mentions history, and @nagydani's attestation of 2026-09-07 (A2) names
  key handling and a general objective — *"the API should make it possible to
  write programs similar to the IDE"* — not a history or recall surface. The gap is
  our finding, derived by measuring the shipped surface against that objective;
  the owner ruled it *"let it be, documented"* (2026-09-07). A capability we invented
  against a stakeholder criterion and the owner deferred is deferred-past-release
  debt, which is what `BACKLOG` is for. *(It keeps its `T-` slug: a slug is earned
  when an entry is `ACTIVE` and kept thereafter.)*
- **How the IDE does it** (the shape a later release would expose). The console
  builds recall on the public `on_limit_reached` callback and finishes with
  internal methods (`src/controller/consoleController.lua`): at the vertical
  boundary it calls `IC:history_back()` / `IC:history_fwd()`. A project gets the
  trigger and not the action, so a child copying the console keeps a parallel list
  and drives it with `set_text`. Buildable, not parity. The smallest honest
  capability is a read/navigate pair beside `get_text`, inheriting every boundary
  question `../decisions/input.md`'s `D-CFG-BOUNDARY` already answers.
- **Not the console/project "same space" request** (owner's question, 2026-09-07):
  there is no single input history — one exists per widget instance. The
  console's is built at boot and lives for the session; a project's is built at run
  start and dropped at stop, with its own `UserInputModel` and `History`. A project
  reading its own widget's history crosses no boundary and moves no sandbox. Two
  things make the gap smaller than it looks: a project's history dies with its
  run, so recall is within-run; and `input_history` (`src/main.lua`, 1000) is
  shared as a number, not as a store.
- **Found:** 2026-09-07, by the second analysis of @nagydani's attestation, not by
  the proposal block.
- **Revisit:** a later release that chooses to expose recall on the public surface.
  Not owed by this one.

### `compy.input` in the console environment is required and unmet — DEFERRED, with its own workspace

**The obligation stands and this release does not meet it.** Owner, 2026-09-08: *"tools are not part
of nearest release … making it working in console is a separate design task which we half-designed
(and which shape may change if sandboxing mechanics is reviewed)."*

- **What the release does instead:** removes the `input` member from the console namespace. That
  member was a console-side surface which resolved to whichever widget was current, reaching into
  the running project's widget; removing it rather than making it work means the surface that never
  worked now raises instead of misbehaving, restoring the PR base's asymmetry.
- **The full entry `T-CONSOLE-INPUT-UNUSABLE`** — with the drafted design, its spec, and a draft
  register carrying it — was ACTIVE here until 2026-09-08, then moved into the deferred
  console-input capability's own workspace, not dropped. The design is drafted and unscheduled;
  this release does not ship it.
- **A blocker that precedes the design and is NOT ours:** a module `require`d at the prompt runs in
  the project's environment whenever the project hooks `love.update` or `love.draw` — the project
  loader `setfenv`s each chunk with `get_effective_env()`. Verified at the PR base `3256aac`,
  unchanged by this feature.

### The empty-submit guard is inherited from the console and was never ruled

- **Where:** `src/controller/userInputController.lua`, `submit_flow` —
  `if self.model:get_text():is_empty() then return end`, the second line of the flow.
- **It predates this feature.** The identical line is at the PR base
  (`git show 3256aac:src/controller/userInputController.lua`), inside a `submit()` whose body then
  called `input:evaluate()`. It is the console's rule — an empty line has nothing to evaluate — and
  it became every widget's rule when the widget became project-facing. Nobody generalised it on
  purpose; it was simply already there, and `../decisions/input.md`, `D-DEFACTO-KEPT` is the reason
  it survived unexamined.
- **It is documented but not argued.** `../../input_api.md` states it twice — *"On a non-empty
  submission the order is…"* and *"a `before_submit` veto, an empty widget or a rejecting validator
  all leave it shown"* — and `D-LIFECYCLE-FLAGS`'s ordering table names *"empty guard"* as a step. No
  decision says why, and none weighs it against a project's use.
- **The open question is whether `''` is legitimate content.** For a console line it is not. For a
  project prompt it plainly can be — *"press Enter to skip"*, an optional field, a default the user
  accepts by answering nothing. Today those are unreachable: Enter on an empty widget does nothing
  and the project is not told.
- **One wart it already produces:** `before_submit` runs before the guard, so a project's veto
  callback fires on an empty Enter and the flow then stops silently. With one payload for every
  content callback, that callback will at least receive `''` and be able to tell.
- **Why it is filed rather than fixed:** no stakeholder asked for it, the release already carries
  several deliberate default changes on this surface, and removing a guard that two documented
  sentences describe is a documented-contract change of its own. Filing it converts an inheritance
  into a decision, which is the point.
- **Nothing else depends on it.** In particular the basic surface's *cancellation answers with
  `nil`* does not: Lua's `''` is truthy, so `if text then` separates *answered with nothing* from
  *abandoned* whether or not the guard stays.
- **Found:** 2026-09-07, by the owner asking where the guard came from and whether `''` is legit
  text. The honest answer is that nobody decided it.
- **Revisit:** with any future work on the widget's submit path, or whenever a project needs an
  optional answer.

### T-CTRL-S-UNCLAIMED — the reason bare Ctrl+S stopped closing the buffer is not true

**RULED, moved to `BACKLOG` 2026-09-07** (owner): *"we do not intervene, ship what
was shipped by #45, mark unbound Ctrl+S a tech debt (backlog). maybe they will rebind it later."*

- **Disposition:** bare Ctrl+S ships as #45 ships it — doing nothing in the editor. We do not take our
  old `close_buffer()` back, though we could. The key is theirs to rebind, and re-taking a binding
  they just vacated would re-assert a claim on a surface this release has twice said is not ours to
  define (`D-EDITOR-KEYS` statement 3).
- **The cost, knowingly taken:** before the import, bare Ctrl+S closed the editor buffer; now it does
  nothing. That is a loss against pre-feature functionality. The entry stays in the register to record
  the capability we gave up, so a later reader finds the reason rather than a gap. It does not block
  the release: the code already behaves this way, and the correct reason now sits as a comment on
  `reserved_stop_run` (moved there 2026-09-07, so a future author adding an editor branch meets it at
  the site).
- **The false claim it corrects:** for one day this corpus said *"upstream PR #45 reserves bare Ctrl+S
  for its checkpoint."* It was corrected at four sites the same day (`../decisions/input.md`
  `D-EXACT-RESERVE`; `../internals/user_input.md`'s Ctrl+S walk; `src/controller/editorController.lua`
  `_leave_keys`; `tests/input/input_global_shortcuts_spec.lua`). The claim predates the import — it
  came from `T-DRIFT-PR45`'s filing, written while the merge was still being planned.
- **What is actually true** (measured against the imported base `f4cf338c`): #45's checkpoint is
  `Ctrl+K` and restore is `Ctrl+Shift+K` (`checkpoint_key()` returns early unless `k == 'k'`); #45's
  own `doc/EDITOR.md` lists those two keys for checkpoints and gives `Ctrl+S` a single row, *"Stop
  project"* — the platform reservation, not an editor claim. What #45 changed in `controller.lua` was
  one deletion: the `close_buffer()` on bare Ctrl+S. The only source of "reserved for the checkpoint"
  is a comment #45 left in place of that deletion, which its own bindings contradict.
- **So bare Ctrl+S is UNCLAIMED, not reserved** — and that is the whole point: a reserved key is a
  collision, an unclaimed one is a choice. Our `close_buffer` could have been kept with zero collision,
  so what the 2026-09-04 ruling treated as a forced concession was unforced. Half of that ruling still
  stands — *"#45 holds the product authority"*, since they removed the close in their own subsystem —
  but the other half, *"their checkpoint reservation stands"*, is false.
- **The unbinding is deliberate, not force-push collateral** (checked 2026-09-05, when the owner
  raised the opposite hypothesis). Old #45 at `16eb33d7` is byte-identical on this point: it already
  deleted `close_buffer()`, already carried the misleading comment, already bound checkpoints to
  `Ctrl+K`. The force-push corrected two documentation tables and changed no executable content, so the
  comment has been wrong since #45's first push — a standing contradiction in their tree, not a slip.
- **A second contradiction, and it points at us:** old #45's `doc/EDITOR.md` documented *"Leave editor
  — `Ctrl+Shift+S`"*; the force-push dropped that row but kept the binding, so upstream now has
  `Ctrl+Shift+S` bound but undocumented, with leaving documented only as `Shift+Esc`. That is the key
  our `_leave_keys` supplies. If they are retiring the spelling rather than just de-documenting it, we
  are holding open a door they mean to close.
- **Both contradictions are upstream's to resolve** (owner, 2026-09-05: *"we need to record
  contradictions and sort them out with Vadim"*). Nothing here proposes changing #45; the record is
  only that our ruling rested on a reason #45's own code does not support.
- **Why it was believed:** #45's comment sits inside the block our `RESERVED` table replaced, so it
  read as the authority on the key beside it — even though this project had measured the truth five
  days earlier (recorded checkpoints on `Ctrl+K`/`Ctrl+Shift+K` and "bare Ctrl+S no longer
  closes the editor" as separate facts). A measurement was on disk and a comment was read instead.
- **Found:** 2026-09-05, by the S75 delivery review. **Roadmap:** closed 2026-09-07 —
  it was blocked on the owner ruling in this entry's header, not on work.

### T-LEAVE-KEYS-LOSES-BLOCK — the editor's whole-editor exits do not write an open changed block: two losing doors, both older than #45

**RULED AND MOVED TO `BACKLOG`, 2026-09-07** (owner): *"ship both, document the
defect."* The loss ships knowingly. It left `ACTIVE` because an `ACTIVE` slug is a commitment to fix
before the PR and the owner ruled the opposite, and because the ruling closed the row that
pointed at it — which would otherwise have left this as exactly the visible gap of an `ACTIVE`
slug with no roadmap row behind it. **The release obligation is discharged, not dropped:** the
defect is named in `../decisions/input.md`, `D-EDITOR-KEYS` statement 6 and in the shipping guide's
reservation section, and the guarded exit is pinned by four tests. What remains here is the record.
The architectural half is `T-EXITS-BYPASS-GUARD` below.

- **Where:** `src/controller/editorController.lua`, `EditorController:_leave_keys` — `k == "s"` with
  Shift and not Alt calls `self.console:finish_edit()`.
- **The loss is at `finish_edit`, not at the chord, and there are three entrances** (found
  2026-09-07, session79, by an AST call-hierarchy query the three preceding sessions could not run —
  `lua-lsp` was dead; `mcp__lua-lsp__references` on `finish_edit` confirms it, and `grep` for the
  name finds the same three):
  1. **`Ctrl+Shift+S`** — `EditorController:_leave_keys` (`editorController.lua:72-76`). The chord
     this entry was opened for, and the one the ruling discusses.
  2. **`Ctrl+T`** — `reserved_quickswitch` (`controller.lua:807-822`), the leave-the-editor-and-run
     door. In `app_state == 'editor'` and `is_normal_mode()`, it calls `finish_edit()`, stores the
     returned state and runs the project. `is_normal(m)` is `m == 'nav' or m == 'edit'`
     (`editorController.lua:216-218`), so `edit` — the mode in which a block is open and being
     changed — is included. Same unwritten block, then a project run on top of it.
  3. **`Shift+Escape` in `nav` mode with an empty widget** — `_normal_mode_keys`' `discard()`
     (`editorController.lua:1347-1355`) → `close_buffer()` → `finish_edit()` when fewer than two
     buffers are open (`:203-212`). This one reaches `finish_edit` but does not lose a block — see
     the guard analysis below. It is listed because a fix sited at `finish_edit` has to account for
     it as a caller, not because it is a defect.
- **Doors 1 and 2 lose data; door 3 does not, and the difference is what each checks before it
  leaves.**
  - **Door 1 has no mode guard at all.** `_leave_keys` is called under `if Key.ctrl()` in
    `keypressed` (`editorController.lua:1545-1553`), before the mode dispatch below it, so
    `Ctrl+Shift+S` fires in `edit` mode with a dirty loaded block.
  - **Door 2's guard admits the dangerous mode.** `is_normal_mode()` is `nav or edit`
    (`:216-218`), and `edit` is where a block is open and modified.
  - **Door 3's guard excludes it, and the reason needs no route inventory.** `discard()` branches:
    `is_empty and self.mode == 'nav'` → `close_buffer()`; everything else → `discard_edit()`, which
    is #45's confirming guard. `is_empty` is the widget's (`input:is_empty()`, read once at the top
    of `_normal_mode_keys`), and an unwritten change exists only as text in the widget — the block
    holds what was last written, which is what `discard_edit` compares the draft against. So the
    branch that reaches `finish_edit` runs only with an empty widget, and an empty widget has
    nothing unwritten to lose. That is true however the mode was reached, and it stays true if
    another route into `nav` is ever added. **A route-inventory argument for this was tried and
    abandoned — do not rebuild it;** the widget-is-empty argument above does not depend on one.
  - **A related mis-read lives on its own path**, recorded in `T-EXITS-BYPASS-GUARD`'s third
    bypass: it loses the draft at `leave_edit`, not an open block at `finish_edit`, so it adds no
    door to this entry.
  - **The data-loss surface is therefore two doors, not three, and both predate #45.**
- **Both losing doors are open at #45's own tip, `f4cf338c` (dev + #45), and neither passes through
  `EditorController`.** Both are application-level `Ctrl` chords in `controller.lua`, so neither can
  reach a guard that lives inside `EditorController` — there is no `_leave_keys` at their tip; that
  method is ours.
  - **`Ctrl+Shift+S`** — `controller.lua:592-601`, `project_state_change()`, under
    `app_state == 'editor'`, with #45's own comment beside it (*"bare Ctrl+S is reserved for the
    checkpoint (rework spec 2.6); saving is automatic, leaving is Shift+Esc"*) → `CC:finish_edit()`.
    Unchanged from `af9a5782` (pre-#45).
  - **`Ctrl+T`** — `controller.lua:562-583`, `quickswitch()`, guarded by
    `CC.editor:is_normal_mode()` → `CC:finish_edit()` → `CC:run_project()`. Byte-identical since the
    PR base (`git show 3256aac:src/controller/controller.lua` carries the same three steps under
    the same guard at `:530-548`), and the `RESERVED` table this branch filed it under does not
    exist there (`grep -c RESERVED` → 0).
  - **`finish_edit` itself** — `consoleController.lua:978-991`, identical to ours line for line.
  **So we imported three open doors and invented none.** What is ours is the layer: doors 1 and 2
  were re-expressed as `RESERVED` entries, and door 1 moved to route level. Re-homing a binding is
  adopting it.
- **What #45 did about this class: it built the guard and did not wire the exits to it.**
  `git diff af9a5782 f4cf338c -- src/controller/consoleController.lua | grep finish_edit` is empty,
  and `save_state()` is byte-identical across the import (`:216` before, `:289` after). What #45
  added is the acceptance-and-confirmation discipline inside `EditorController`, none of which
  exists at `af9a5782`: `accept_block` (validate → size-check → `record_write` → `save`, with a
  refusal path that keeps the block open because *"a failed write must not read as accepted"*),
  `discard_edit` (compares the draft against the original and, when they differ, sets
  `pending_confirm = 'discard'` and asks *"discard the changes? Confirm [Enter] / Cancel [Esc]"*),
  `leave_edit` (the clean exit), `_confirm`, `refuse`, `record_write`, `_reject_oversized`. So the
  editor already knows how to protect a dirty block, and the two whole-editor exits never ask it —
  while `discard_edit`, the key #45 itself owns, does. `finish_edit` is console-level; it predates
  the feature and predates #45, and its name promises a finish it does not perform: it stores the
  clipboard and drops the buffers.
- **Door 3 is #45's own wiring, and #45 guarded it.** At `af9a5782` (pre-#45) `close_buffer` already
  existed with the same `finish_edit()` call (`editorController.lua:122-130`), but nothing called
  it (`grep -c close_buffer` → 1, the definition alone). #45 gave the dead sink a key — its own
  spec-2.3 `discard()` path — and routed every case that could lose something to `discard_edit()`
  instead, sending only the empty-and-nav case to the sink. The transferable point: #45 fixed the
  class at the block level, everywhere it owns the key, and left the two whole-editor exits — which
  it did not author — calling `finish_edit` as before.
- **#45's own comment sits on door 1 and names a different key as the exit:** *"bare Ctrl+S is
  reserved for the checkpoint (rework spec 2.6); saving is automatic, leaving is Shift+Esc"*.
  Shift+Esc is guarded twice — a dirty block goes to `discard_edit()`'s confirmation, and only
  after `leave_edit()` has cleared it does a second press reach `close_buffer()` → `finish_edit()`.
  The editor cannot be left with unwritten changes via the key #45 documents as leaving, which
  matches its author's account of `Ctrl+Shift+S` as inherited and absent from the editor spec.
- **One parity divergence of ours, recorded here because it was not written down anywhere else.**
  Their door 1 has no Alt guard; our `_leave_keys` is `k == "s" and Key.shift() and not Key.alt()`.
  So `Ctrl+Alt+Shift+S` leaves the editor at `f4cf338c` and does nothing on this branch. Ours is the
  narrower binding — defensible, and still a deviation introduced by the re-homing rather than
  ruled. It is not covered by the tests (`input_global_shortcuts_spec.lua` presses
  `lctrl`/`lshift`/`s` only).
- **This settles the parity half of the owner's standing ruling** (*"ship exactly what #45 ships;
  if its destructive behaviour, escalate"*): at #45's tip both losing doors lose the block, so
  shipping them is exact parity, and any acceptance step we add would be a deliberate divergence
  rather than a correction. The escalation half was ruled on 2026-09-07: ship
  both exits, documented — so no acceptance step is taken.
- **Consequence: the fix is a routing question, not a policy question.** `discard_edit`'s confirm
  is already the policy, authored by #45 and consistent with @dsent's stated direction; what is
  missing is that `finish_edit` does not go through it. The real cost is that the guard is modal
  and deferred while the exits are synchronous: `pending_confirm` is consumed on the *next*
  `keypressed` (`editorController.lua:1518-1530`), while `reserved_quickswitch` runs
  `finish_edit()` and `run_project()` in one call. Confirming before leaving would mean those
  callers can no longer assume the editor is gone when the call returns — that design work is what
  was weighed on 2026-09-07 and declined to take: both exits ship as a documented defect. The
  architectural half has its own entry, `T-EXITS-BYPASS-GUARD` (`BACKLOG`), opened 2026-09-07 by
  owner directive; this entry stays the record of the specific chord and of what our re-homing
  adopted.
- **An acceptance step at the chord would leave door 2 open, and door 2 is the worse one** — it
  loses the block *and* starts a project run, so the user's next screen is not the editor. An
  acceptance step at `finish_edit` closes all three at one site: smaller in lines, larger in blast
  radius, since `finish_edit` is a pre-existing path with a pre-existing caller. The ruling chose
  neither on 2026-09-07; the comparison is stated here so whoever fixes it starts from it rather
  than redoing it.
- **What the path does, verified rather than assumed.** `ConsoleController:finish_edit()` calls
  `self.editor:save_state()` then `self.editor:close()`; `EditorController:close()` runs
  `self.input:clear()`, replaces `self.model.buffers` with a fresh `Dequeue()` and empties
  `self.view.buffers`. There is no acceptance step for an open, changed block anywhere on that
  path — `save_state()` stores the clipboard, not the buffer. So a user editing a block who presses
  `Ctrl+Shift+S` loses that block's changes silently.
- **Attested by the author of PR #45**, 2026-09-06, about the same chord on his layer: it *"goes
  past the acceptance gate — an open changed block is not written"*. He calls the binding
  inherited, absent from the editor spec, and something he will raise with @dsent separately. **The
  attestation was given in Russian and is recorded in English**, summarised rather than translated:
  the wording is ours, the claims are his. The contract it belongs to is `../decisions/input.md`,
  `D-EDITOR-KEYS`.
- **Provenance: ours, and that is the point.** The binding is upstream's
  (`git show af9a5782:src/controller/controller.lua`, the `k == "s"` block → `Key.shift()` →
  `CC:finish_edit()`), and it carried the defect there. This branch re-supplied it at route level
  during that merge — `_leave_keys` is a rename and relocation of our own `_save_keys` — without
  checking what the path it calls actually does. Re-homing a binding is adopting it.
- **Why it is not simply upstream's to fix.** On their layer the chord is one they are questioning;
  on ours it is one we deliberately re-expressed at a new layer while resolving a merge conflict,
  and the argument recorded for that placement was about which layer owns the reservation, never
  about what the call loses. Both can be true: they may retire the chord, and we would still have
  shipped it.
- **Reachability:** any editor session with an open, modified block — not hypothetical, it is the
  ordinary way a user might try to leave.
- **Interaction with the direction of travel.** @dsent's stated redesign collapses the exit
  combinations and requires confirmation for anything that can lose data, so this path is contrary
  to where the product is going as well as to what it does today.
- **Found:** 2026-09-06, following Vadim1987's attestation to our own copy of the
  chord. Nothing in our suite covers it — the re-pin that touched this area asserted which function
  fires, not what the file ends up containing.
- **Behavioural parity with #45 is ruled, and it is already met** (owner, 2026-09-06): *"we need to
  ship it with exact behavior #45 ships it. If its destructive behaviour, escalate."* Parity holds:
  the divergence is which layer owns the chord, not what the user gets — theirs is
  application-level guarded by `app_state == 'editor'`, ours is route-level under `Key.ctrl()`
  ahead of mode dispatch, and both reach every editor mode and the same `finish_edit()`. Measured:
  `grep -n "reserved_stop_run\|RESERVED" src/controller/controller.lua` shows bare `ctrl+s` mapped
  to the stop-run reservation, which no-ops outside a run, and `ctrl+shift+s` absent from that
  table on our side entirely — so there is no behaviour to change. The escalation condition fires,
  because the attested behaviour on the other layer is destructive too.
- **Roadmap: nothing open — the row that carried this closed.** That row was the escalation, and the
  owner ruled it on 2026-09-07: *"ship both, document the defect."* The ruling's persistent home is
  `../decisions/input.md`, `D-EDITOR-KEYS` statement 6, with the shipping guide's reservation
  section beside it — cited that way on purpose, because a `wip/` row id stops resolving when the
  feature's working tree is deleted and this entry outlives it.

### T-EXITS-BYPASS-GUARD — the editor's discard guard cannot be reached from the two keys that leave the editor

**Opened 2026-09-07 by owner directive** — *"record the debt on these two keys, probably
generalized to need of re-architecturing or reimplementing the guard so that they could use it
too."* This is the general entry; `T-LEAVE-KEYS-LOSES-BLOCK` remains the record of the specific
chord and of what our re-homing adopted.

- **The two keys, with full guard chains** (ours, at HEAD): `Ctrl+Shift+S` →
  `EditorController:_leave_keys` → `console:finish_edit()`, under `if Key.ctrl()` ahead of the
  mode dispatch, so it fires in `edit`; and `Ctrl+T` → `reserved_quickswitch` (`controller.lua`) →
  `finish_edit()` → `run_project()`, guarded by `is_normal_mode()`, which is `nav or edit`. Both
  reach `ConsoleController:finish_edit()`, which calls `save_state()` — the clipboard — and
  `close()`, which drops `model.buffers`. No acceptance, no confirmation.
- **The guard exists, works, and is out of reach, by two different routes.**
  `EditorController:discard_edit` compares the draft against the original and, when they differ,
  sets `pending_confirm = 'discard'` and asks *"discard the changes? Confirm [Enter] /
  Cancel [Esc]"*. `accept_block` writes with a refusal path that keeps the block open when the
  write fails. Both are methods on `EditorController`, and both exits bypass them. `Ctrl+T`'s
  reservation fires in `controller.lua` before the key enters the editor at all. `Ctrl+Shift+S`
  does enter it — `_leave_keys` is a method on `EditorController` — but it runs under
  `if Key.ctrl()` ahead of the mode dispatch and calls the console directly, so `discard()` inside
  `_normal_mode_keys` is never reached. Same outcome; only the first is a layering problem.
- **The loss is pinned as of 2026-09-09, and a fix must flip two cases** (owner
  ruling): `tests/input/input_editor_keys_spec.lua`, *"Ctrl+Shift+S leaves (w/o
  confirmation)"* and *"Ctrl+T leaves and runs (w/o confirmation)"*. They assert that the open
  changed block reaches no write on the way out — the behaviour the release knowingly ships
  (`../decisions/input.md`, `D-EDITOR-KEYS` statement 6). The `(w/o confirmation)` marker is what
  keeps a green test from reading as the specification: unpinned, these two cases would have sat
  outside the regression net that guards the route around them.
- **This is the architectural half, and it is why the entry is general.** The mismatch is not a
  missing `if`: the guard is modal and deferred — `pending_confirm` is consumed on the *next*
  `keypressed` (`editorController.lua`) — while the exits are synchronous; `reserved_quickswitch`
  calls `finish_edit()` and `run_project()` in one breath. Routing the exits through the guard
  means the callers can no longer assume the editor is gone when the call returns, which is a
  contract change at three call sites rather than a patch at one.
- **Direction, recommended and NOT committed** (the same shape `T-EDITOR-KEYS-DEFAULT-OPEN` uses):
  give the editor a *may I leave?* step that the exits must pass — either `finish_edit` returning a
  refusal that its callers honour, or an editor-side `request_leave(on_granted)` that runs the
  existing confirmation and completes the exit on confirm. Either way the policy stays where #45
  put it and only the reachability changes. Deciding between them is design work, not a sweep.
- **Provenance: neither key is ours, and neither is #45's.** Both are at the PR base; `Ctrl+T`'s
  editor arm is byte-identical across the import, and #45 changed the `Ctrl+S` block only to
  remove bare Ctrl+S, leaving the Shift leave untouched. What #45 did do is fix this class at the
  block level — `discard_edit`, `accept_block`, `leave_edit` — and route its own `Shift+Esc`
  correctly through it. The exits it did not author are the gap, and its author has called the
  chord inherited and absent from the editor spec. What ours adds is layer, not defect:
  `Ctrl+Shift+S` was re-expressed at route level as `_leave_keys` and `Ctrl+T` became a `RESERVED`
  entry. Re-homing a binding is adopting it, which is the argument `T-LEAVE-KEYS-LOSES-BLOCK` makes
  and this entry inherits.
- **A third bypass, and it does not need an exit at all** (found 2026-09-07 by the S79 delivery
  review, verified independently by the parent before being recorded here). `Ctrl+J` is not
  mode-gated: in `navigate()`'s tail (`editorController.lua:1485-1489`) it runs in `edit` as well
  as `nav` — `follow_require()` → `console:edit(...)` → `EditorController:open(...)` →
  `set_mode('nav')` — and `open()` clears neither the loaded block nor the input (`:114-117`). So
  the widget arrives in `nav` still holding the draft. A following `Shift+Esc` then finds
  `is_empty` false, falls through to `discard_edit()`, meets its `if self.mode ~= 'edit' then
  return self:leave_edit() end` early return (`:581-584`) and destroys the draft with no
  confirmation.
  - **It is a guard bypass rather than a fourth door:** nothing here reaches `finish_edit` and the
    editor is not left. The loss is the draft, and the mechanism is that the guard tests `mode` as
    a proxy for *is there something to lose*, which `Ctrl+J` breaks by moving the mode out from
    under a live draft.
  - **Provenance: inherited, both halves from different places.** `follow_require` is at the PR
    base and every revision since (`git show 3256aac:src/controller/editorController.lua | grep -c
    follow_require` → 2, same at `af9a5782` and `f4cf338c`); `discard_edit`'s early return is #45's
    own, part of the guard it built. The combination is reachable at #45's tip, so parity is
    untouched and the ruling stands unchanged.
  - **It narrows two sentences written the same day, below what the code now shows:**
    `../decisions/input.md`, `D-EDITOR-KEYS` statement 6 says two exits, and the shipping guide
    calls `Shift+Esc` *"the only one that asks before discarding"*. Both are true of the exits;
    neither covers this path. Marked at both sites rather than rewritten, because widening a ruled
    statement is the owner's call, not a correction.
  - **The category question was put to the owner and RULED, 2026-09-07:** *"I do not know if other
    fragile modes exist or not. but we certainly are not spinning-off to fixing #45 work, we have
    own purpose."* The question stands as asked — a guard keyed on `mode` is only as good as the
    invariant *mode changes imply the draft was dealt with*, and `open()` breaks that invariant
    without touching the guard, so whether other mode moves leave a live draft is open and
    deliberately unmeasured. The ruling is not that the answer is no; it is that finding it out is
    not this feature's work. The guard is #45's, both halves of this path predate this branch, and
    an inventory of mode moves would be a spin-off into another author's subsystem. The entry is
    the record and stays `BACKLOG`; the *Direction* bullet above remains a recommendation to
    whoever owns the editor, not a commitment of ours.
- **`Ctrl+T` contradicted `D-EDITOR-KEYS` until the same day it was found** (found 2026-09-07,
  while checking the deprecation ruling). Statement 2 reads: *"Leaving and discarding are always
  `Shift+Esc`. There is no second way out that the contract recognises, which is what makes an
  unrecognised one worth finding rather than preserving."* Its key table named `Shift+Esc`, bare
  `Escape`, `Ctrl+S` and `Ctrl+Shift+S`, and `Ctrl+T` appeared nowhere in it — a second way out,
  from `edit` mode, that loses the block and then starts a project run, so the contract's own test
  applied to it by the contract's own words. The owner ruled the amendment hours later: `Ctrl+T` is
  now in the table, with statement 6 beside it. Related but not the same as the unmeasured-coverage
  debt (rows the suite does not pin) — this was a row the contract did not have.
- **Reachability:** any editor session with an open, modified block — the ordinary state of
  editing.
- **Coverage:** the guarded exit is now pinned — `tests/editor/editor_spec.lua`, *"leaving through
  Shift+Esc (2.3)"*, four cases, added 2026-09-07 by owner directive. The two unguarded exits are
  deliberately unpinned: a passing test over them would fix the loss in place.
- **Why `BACKLOG` rather than `ACTIVE`, and this is the assistant's placement, not a ruling.** An
  `ACTIVE` slug is a commitment to fix before the PR, and the fix is a contract change across three
  call sites in a pre-existing path. Shipping both doors is exact parity with #45, which the
  owner's standing ruling asks for; the escalation half was taken on 2026-09-07 and
  ruled *ship both, documented*. If the owner rules the re-architecture into the release, this
  entry moves to `ACTIVE` and needs a roadmap row (every `ACTIVE` entry does).

### T-EDITOR-KEYS-DEFAULT-OPEN — our widget acts on every editor key the editor does not block, and the block list is theirs

- **Where:** `src/controller/editorController.lua`, `_normal_mode_keys` — `passthrough` initialises
  to **`true`** and `block_input()` clears it; the tail reads `if passthrough then
  input:keypressed(k) end`. So `src/controller/userInputController.lua`'s `keypressed` runs on the
  editor route for every key the editor did not explicitly claim.
- **The defect is not that a seam exists. It is that the seam's default is open and its enforcement
  lives in the other feature's code.** Our blast radius on that route is decided by `block_input()`
  calls in a file this branch does not own; when that file changes, nothing fails, because an
  expectation cannot fail. That is why `T-NAV-ESCAPE` was found by an unrelated spec rather than by
  a test.
- **The gate is upstream's and pre-dates this branch entirely.**
  `git show 3256aac:src/controller/editorController.lua | grep -c "passthrough\|block_input"` →
  **14**, identical at `af9a5782`; #45 grew it to **29**, which is also HEAD. We did not turn an
  allow-list into a block-list — the block-list was always the outer gate, and it is still theirs.
- **The widget's own `app_state == 'editor'` fork was not an allow-list either.** At the base its
  editor arm ran nearly the whole handler set — `removers`, `horizontal`, `vertical`, `newline`,
  `modify`, `copypaste`, `selection`, `submit` — so an unclaimed key did almost everything, not
  nothing. The fork differed both ways: the editor arm omitted **`cancel`**, and the other arm
  omitted **`modify()`**, so the difference that matters for this class is `cancel` — the one
  handler the un-fork added to the editor route. `modify()` kept its editor-only scope through the
  un-fork as a constructor flag, so it moved nowhere.
- **What Phase R actually changed is one handler.** `affc9320` (2026-07-21, *"un-fork UIC
  app_state"*) removed the fork; `modify()` kept its editor-only scope as a constructor flag
  (`-  if love.state.app_state == 'editor' then / -    modify()` → `+  if self.allow_modify then
  modify() end`), and `cancel` joined the editor route. Nothing else moved. That one handler is
  `T-NAV-ESCAPE`, and it was latent until #45: the editor claimed Escape, so our cancel was
  unreachable; #45 moved the load onto Enter and the discard onto `Shift+Esc`, stopped claiming
  bare Escape, and the latent path went live. That is the `R11` class exactly — *they changed a
  line we moved*.
- **Consequence for release scope:** the class's other live members (`Ctrl+D`, `Shift+Enter` in
  nav) are pre-existing upstream behaviour, not regressions this branch introduced — `modify()` and
  `newline()` reached the editor route at the base too. The flags work removes our only contribution
  (the cancel), after which this branch adds nothing to this class.
- **Known live instance: one.** `T-NAV-ESCAPE` — bare Escape reaches `cancel_flow`, whose clear is
  hardwired past the callbacks. **Cleared instances:** `Alt+↑/↓` (our `swap_line` is destructive,
  but the editor takes the whole `Alt` branch with `block_input(); return`, and its comment records
  the deliberate retirement of the block swap).
- **The rest of the class was probed 2026-09-06** (throwaway spec against `input_fixture`, driving
  the real wired editor; nothing under `tests/` touched), and the result decides whether the seam
  must be closed structurally for this release:
  - **`Ctrl+D` in nav — LIVE.** The widget's `modify()` duplicates its current line: content goes
    from one empty line to two. `allow_duplicate_line` is true for exactly this widget.
  - **`Shift+Enter` in nav — LIVE.** `newline()` adds a line feed to the widget's pending input.
  - **bare `backspace` and `Ctrl+W` in nav — inert.**

  **The mechanism behind each** (added 2026-09-07 so the list survives without the probe, which was
  a throwaway spec and is gone — that is itself the point of the entry):
  - **Why any of them arrive:** `_normal_mode_keys` leaves `passthrough` true for keys it does not
    claim, and the tail runs `input:keypressed(k)`. Nav claims `ctrl+c/x/v`, `ctrl+z/y`, `ctrl+k`,
    `ctrl+enter`, `shift+delete`, `shift+insert`, `shift+escape`, the `alt`/`ctrl` arrow families,
    plain `delete` and plain Enter — **not** `ctrl+d`, **not** `shift+enter`.
  - **`Ctrl+D`:** the widget's `modify()` is `if Key.ctrl() and k == 'd' then
    input:insert_text_line(input:get_current_line())`, reached because the call site is
    `if self.allow_duplicate_line then modify() end` and the editor constructs its widget with that
    flag **true**. In nav the user is not typing, so the effect lands in a pending input nobody is
    looking at: one empty line becomes two. Cruft, not loss — `doc/EDITOR.md` documents *"Duplicate
    current line — Ctrl+D"* under **Input**, so the handler is wanted; what is wrong is only the
    context it is reachable from.
  - **`Shift+Enter`:** `newline()` is `if Key.shift() and Key.is_enter(k) then input:line_feed()`.
    Same shape, same document (*"Insert newline — Shift+Enter"*).
  - **Plain Enter, the double dispatch:** the editor accepts the block **and** the widget's
    `submit_flow` runs. Inert because the editor sets **no callbacks** on its widget and `auto_hide`
    is `nil` there, so the flow reaches its end with nothing to call and nothing to hide.
  - **`backspace` / `Ctrl+W`:** `removers()` runs, but `backspace()` on an empty pending input has
    nothing to delete, and `backspace_word()` is gated on `input.editing`, which nav is not.
- **`always_shown` is NOT the guard for any of this, and the distinction matters because it is the
  obvious place to look** (owner's question, 2026-09-07). The editor's widget **is** `always_shown()`
  (`editorController.lua`, with the search strip likewise), and the flag guards **`hide()` alone** —
  `cancel_flow` does not consult `self.always`, so an Escape that reaches the widget clears whether
  or not the flag is set. Restoring or keeping that guard would not have prevented `T-NAV-ESCAPE`;
  what prevents it is the cancel flow ceasing to destroy unconditionally, which is the flags work and is
  on **our** side of the boundary — no change to the editor's dispatch required, which is what
  the owner judged.
  - **Plain `Enter` on the accept path — LIVE, and it confirms the double-dispatch.** Instrumenting
    `submit_flow` shows **one call** after Enter accepts a block in edit mode: the editor accepts
    *and* the widget's submit flow runs. Both lifecycle verbs double-dispatch, exactly as the
    symmetry predicted.
- **But none of the live members is a defect, and that is the finding.** `Ctrl+D` and `Shift+Enter`
  are **documented editor behaviour** — `doc/EDITOR.md` lists *"Duplicate current line — Ctrl+D"*
  and *"Insert newline — Shift+Enter"* in the **Input** section, and its Editor section reads
  *"same as Input, except for:"*. So the editor **wants** those keys in its text field; what they
  leave behind in navigation is stray content in a pending input, cruft rather than loss. The
  `Enter` member is observably inert (no callbacks, `auto_hide` nil). After the cancel flow stops
  destroying content, this class has no member that loses data or contradicts the editor's own
  keymap — which is why closing it structurally is a recommendation and not a release gate.
- **What bounds the damage today, and it is worth stating because it is what makes a fix cheap:**
  the editor sets **no callbacks at all** on its widget
  (`grep -n "callbacks\|after_submit\|before_cancel" src/controller/editorController.lua` → no
  hits), so it carries `default_callbacks()`; and `auto_hide` is `nil` on it, being reachable only
  through `configure`, which is the project surface. So `submit_flow` is **inert** there and
  `cancel_flow`'s only live effect is the unconditional clear.
- **Reachability:** every key press in the editor. Harmless per-key until our side grows a
  destructive handler for a key their side stops claiming — which is what happened once already.
- **What the decline does and does not accept.** It does **not** accept shipping a defect of ours
  in the hope it will not fire: after the flags work this branch contributes **no** member to the
  class. What it accepts is **declining to restructure a pass-through that is upstream's,
  pre-dates us, and whose current members are their documented behaviour**. The residual risk is
  real and it is invisibility, not damage: nothing fails when either side changes, because an
  expectation cannot fail.
- **A mitigation cheaper than the migration, and it addresses exactly the invisibility:** pin the
  measured members in a spec — `Ctrl+D` and `Shift+Enter` in nav leaving stray content, plain Enter
  double-dispatching inertly, bare `backspace` and `Ctrl+W` inert — so that the next change on
  either side **fails a test instead of being found by an unrelated one**. That is what the class
  has never had, and it is the reason `T-NAV-ESCAPE` was found the way it was. **Not scheduled:
  proposed**, and it belongs with the sprint that already writes the editor's
  regression net.
- **Found:** 2026-09-06, by a seam analysis, looking for the class rather than the
  instance.
- **RULED 2026-09-06: the release does NOT close this structurally.** The owner: *"we decided it
  does not. We provide compatibility and document a **recommendation** to move somewhere (likely in
  debt backlog) — maybe even with specific direction or migration plan."* So the seam stays open,
  the class ships registered rather than closed, and **what this entry owes is the direction**,
  which is written below rather than cited. The reason for the decline is the measurement two
  bullets up: once the cancel flow stops destroying content, **no member of this class loses data
  or contradicts the editor's own keymap** — against which the migration is a large diff in a
  subsystem this branch does not own, with no line in the PR's justification table, in a release
  whose gate is reviewability from `doc/input_api.md` alone.
- **The recommended direction, stated here because the analysis that produced it does not survive
  the release.** Move the editor onto the same `dispatch(shortcuts, hooks, widget, event, trigger,
  ...)` chain the console and project routes already use. Four things make it a recommendation
  rather than an aspiration, and each was measured rather than argued:
  1. **The machinery was extracted for exactly this.** `dispatch` is a free function over plain
     tables (`src/controller/projectInputController.lua`) and `build_widget_api(get_widget,
     get_active_flag)` is a factory — `../decisions/input.md`'s implementation note says in terms
     that this was *"so that the mechanism a future console/editor adoption (`D-ROUTE-OWNS`) needs is
     reusable rather than bound to one controller's instance fields"*.
  2. **The shape fits, including the parts that are not combo-shaped.** `dispatch` runs
     `shortcuts[combo]` → `hooks[event]` → widget-terminal, each consuming on truthy. The editor's
     combo-shaped handlers map onto the shortcut table; the three that are not — submit/open selected
     by *is-empty and plain Enter*, the mode-dependent ownership of up/down, and the ordered
     fall-through — belong in `hooks.keypressed`, which runs after the combos, before the widget,
     with full access to mode and state.
  3. **The file was free when this was measured**, and that is a condition rather than a fact: the
     edge did not touch the editor route at all. **Re-measure before acting** — `git diff --stat
     <edge-base> <edge-head> -- src/controller/editorController.lua
     src/controller/userInputController.lua src/model/editor/` was empty on 2026-09-06 and says
     nothing about a later edge.
  4. **There is a safety net and it is the editor author's own** — the import brought **111** cases
     in `tests/editor/editor_spec.lua` and **29** in `tests/editor/buffer_spec.lua`, asserting his
     key semantics. Re-derive with `grep -c "it(" tests/editor/editor_spec.lua
     tests/editor/buffer_spec.lua`.
  **What it buys:** the class is closed structurally rather than registered, so it cannot acquire a
  new member the next time either side moves. **What it costs** is stated in the decline above, and
  whoever takes it also owes a device pass — a restructured editor route is a smoke surface.
  *(Do not look for an older plan: the fork-options study that predates this argues the seam INTO
  existence — option E is what we implemented — so it is stale for this purpose in the opposite
  direction from the usual one.)*
- **Roadmap:** the instance is tracked by `T-NAV-ESCAPE` (RESOLVED, above). **This entry is the class, it is `BACKLOG` by the
  2026-09-06 ruling, and it is deliberately not slugged** — a slug is a commitment to fix before
  release and the ruling is that we do not. It is kept in full rather than compacted because the
  direction above is the deliverable the ruling asked for.

### PROPOSAL: the `love.*` capture is a seam, and the honest options are to wrap it or to drop it

- **Where:** `D-HOOKS-SEEDED` — a project's `love.*` handler is captured at
  activation and seeded as `compy.input.hooks[event]`, where it runs in hook
  position and its return value now means *consume* (`projectInputController.lua`,
  `dispatch`). LÖVE ignores that return; nothing about the signature changes and
  code written against LÖVE works as expected.
- **State:** not a defect — a seam the owner names as *dirty but justifiably
  tolerable and easily removable* (2026-09-05). Recorded so the tolerance is a
  stated position rather than something a later reader has to infer from the fact
  that nobody objected.
- **The two honest alternatives, neither taken:**
  - **Wrap the seeded handler in `fn.stop_here`**, which would imitate the old
    effect exactly: under LÖVE the project's handler *was* the end of the line, and
    `stop_here` returns `true` unconditionally (D-STOP-AND-SIDE). This is what a
    released platform would owe its users. It is declined here because the
    platform is not released — no userbase beyond our own reach, and the release
    is already backwards-incompatible, so a safety net paid for with a second
    implicit behaviour buys nothing.
  - **Remove the capture entirely**, decoupling `compy.input` from LÖVE's surface.
    The argument is ownership: a project that wants to overwrite a LÖVE primitive
    and break dispatch should be able to, and the capture quietly denies it.
    This is the owner's preferred direction, explicitly for a future discussion
    and not this release.
- **Why it is worth an entry:** the two alternatives point in opposite directions
  — one adds compatibility, the other removes the coupling. What decides between
  them is whether the platform has users, a fact about the release rather than
  about the code. An entry keeps that reasoning attached to the seam; a later
  reader would otherwise re-derive it or, worse, treat the seam as load-bearing.
- **Provenance:** ours. The capture is this branch's.
- **Revisit:** after the release, and a later decision if it comes up sooner. Not
  release scope: nothing here is broken, and both options are behaviour changes.

### PROPOSAL: a callback can be installed two ways, and neither is documented as primary

- **Where:** `compy.input.show{ on_text_entered = ... }` and
  `compy.input.callbacks.on_text_entered = ...` both install the same callback.
  `consoleController.lua`'s `api_show`/`api_configure` funnel config keys into the
  same store the `callbacks` table writes (`merge_callback_keys`), so the two are
  one mechanism with two spellings.
- **Scope, corrected 2026-09-05:** this entry is about the two spellings only.
  That the two are not offered for *every* callback is a separate question with
  its own entry — *"the three installation paths do not accept the same set"*,
  below. They were briefly filed as one and the owner separated them: they are
  different contradictions and each is owed its own reading.
- **State:** not a defect — an unweighed API-shape question, raised from the
  reader's side rather than found in code. `internals/examples/repl.md` showed a
  project installing `after_submit` through the table and `on_text_entered`
  through the `show` config in the same six lines, which is what prompted it:
  *"config installs callback, which raises a question of API shape (why not have
  separate callbacks interface as the only way to set callbacks?)"*
- **Why it is worth an entry rather than a fix:** the guide documents both paths
  and neither is wrong, so nothing is broken today. What is missing is a stated
  reason to prefer one, which means every example picks by taste and a reader
  infers a distinction that does not exist. This is distinct from
  Decision 37, which settled why `on_text_entered` and `after_submit` both
  exist; this asks why each of them has two installation sites.
- **Provenance:** ours. Both spellings are this branch's.
- **Revisit:** the holistic pass over the proposal block, and low
  priority there (owner, 2026-09-05) — nothing in the release depends on the
  answer. That row already weighs API-shape items against the shipped surface
  and rules in-release or after it; this is the same kind of question from a
  different source. Registered here rather than left in a review marker, because
  a marker dies with the document it sits in (2026-09-04).

### PROPOSAL: the three installation paths do not accept the same set, and one of them catches typos while another does not

- **Where:** `show()`, `configure()` and `compy.input.callbacks`. The matrix,
  read out of `consoleController.lua` (`CALLBACK_KEYS`, `WIDGET_KEYS`,
  `SHOW_ONLY_KEYS`, `LIFECYCLE_KEYS`) and confirmed by running the surface, not
  by reading it:

  | key | `show{}` | `configure{}` | `callbacks` table |
  |---|---|---|---|
  | `on_text_entered`, `on_limit_reached`, `validator`, `highlighter` | yes | yes | yes |
  | `before_submit`, `after_submit`, `before_cancel`, `after_cancel` | **raises** | **raises** | yes |
  | `prompt`, `auto_hide` | yes | yes | n/a — not callbacks |
  | `text`, `cursor`, `force` | yes | **raises** | n/a — not callbacks |

- **Two asymmetries, and only one of them is ruled.** The `text`/`cursor`/`force`
  row is `D-CFG-BOUNDARY`'s show-only category and has a stated reason: the user
  owns that content and only activation seats it. The lifecycle row has no such
  ruling — four callbacks are settable three ways minus two, and the rule a
  reader must infer is *"content callbacks may ride a config table, lifecycle
  callbacks may not."*
- **The sharper half, found 2026-09-05: the paths differ in whether a typo is
  caught.** The config table is closed — `show{ on_txet_entered = f }` raises
  and names the key (`D-UNKNOWN-RAISES`). The callbacks table is a plain Lua
  table with no guard — `compy.input.callbacks.on_txet_entered = f` is accepted
  silently, stored, and never fires. So for the four callbacks that have both
  spellings, one spelling catches the misspelling and the other loses it, and a
  project cannot tell from the surface which it is using. Verified by driving
  the real project route through `tests.helpers.input_fixture`; no spec pins
  this difference, in either direction.
- **It may well be justified, and the reframing states a justification for the
  first asymmetry** (owner, 2026-09-05): a project names content callbacks at the
  moment it asks a question and sets lifecycle callbacks structurally, so the
  frequent case gets the short spelling. `D-EDIT-CALLBACKS` and
  `D-EDIT-LIFECYCLE` own the two sets. **What has not happened is either
  asymmetry being weighed on its own terms**, and the outcome may equally be
  *justified*, *tolerated*, or *worth closing*. This entry does not prejudge it.
  Two loose ends for whoever weighs it: `on_text_entered` fires **on the submit
  path** while belonging to the content set, and the unguarded table is a
  silent-failure mode rather than a shape preference.
- **Provenance:** ours, and it was raised once before and lost.
  `internals/examples/repl.md`'s first marker asked, among three proposals,
  *"or allow installing all callbacks via show?"* — this question. The 2026-09-04
  disposition read the marker as answered by Decision 37, which answers only the
  first of the three, and filed only the third. A marker carrying several
  proposals is dispositioned proposal by proposal, which is the transferable
  half.
- **Revisit:** a later decision, low priority (owner, 2026-09-05) — nothing in the
  release depends on the answer. The typo half may not wait that long if the
  weighing decides an unguarded surface is a defect rather than a shape.

### `release_keyboard_route` is named for a lifecycle step that no longer exists

- **Where:** `controller.lua`, `Controller.release_keyboard_route`. One call
  site: `consoleController.lua`, `run_project`'s failure branch.
- **State:** the name asserts three things that are not true. It is not
  keyboard-specific — it calls `project_input:deactivate()`, dropping the whole
  route, and empties the derived click slots. It is not a lifecycle release —
  the `'running' → 'project_open'` release is gone and every channel shares one
  lifetime ending at the project's stop (`../decisions/input.md`,
  D-ROUTE-LIFETIME as amended). And it is not reached on the transition it
  names: the crash path is its only caller.
- **Why this is not simply a rename, which is why that pass left it.** The
  caller follows it immediately with `clear_user_handlers`, which clears every
  bindable channel; the two together are the crash teardown, and this one covers
  the part the other does not. Naming it accurately means first deciding whether
  they should be one function — a design call, not a docs sweep. A rename
  chosen without that decision would just be a second inaccurate name.
- **What it costs today:** the doc comment now opens with *"NOT a lifecycle
  step, despite the name"*. That is a comment paying rent for a name, which is
  the smell — not a defect. No behaviour is wrong and no reader is misled now
  that the comment says so.
- **Trigger:** revisit when the crash teardown is touched, or if
  `clear_user_handlers` changes. Found 2026-09-02, in an earlier findings
  triage that proposed the rename and did not have this dependency in view.
- **Not slugged** — no commitment to fix.

### `_set_text_line` has an unreachable table branch

- **Where:** `src/model/input/userInputModel.lua` —
  `UserInputModel:_set_text_line`, where
  `elseif type(text) == 'table' and ln == 1 then` is nested inside
  `if type(text) == 'string' then`, so its guard can never hold.
- **State:** dead code that reads as a supported shape. A reader looking for
  "can `_set_text_line` take a list?" finds a branch saying yes, and it has
  never run.
- **Provenance:** pre-existing, and the same fossil family as the dead
  `_update_cursor` call that fix retired — a shape carried through a
  migration and never re-checked. Found by that row's cold peer review,
  2026-09-01.
- **Not slugged**; nothing depends on it and no behaviour changes when it goes.
- **Revisit:** a one-line deletion inside the `_update_cursor` review below —
  same function, same pass, and the two should not be walked twice.

### Content normalisation treats `\n` but not `\r`

- **Where:** `src/util/string/string.lua` — `string.lines` splits on `'\n'`;
  nothing in `src/model/input/`, the string utilities or
  `userInputController.lua` mentions `'\r'` at all.
- **State:** `set_text("a\r\nb")` yields `{"a\r", "b"}`. The stray `\r` stays
  inside a line and the model counts it as an ordinary column, so the line
  measures one character longer than it displays and the caret can be seated on
  a position that renders nowhere. That is precisely the ambiguity
  `D-CONTENT-NORM` says normalisation removes — the decision is now scoped to
  `\n` explicitly because that is what the code implements.
- **Reachable:** a project setting content it read from a CRLF file. Whether the
  clipboard path is exposed is unverified — SDL may normalise
  `love.system.getClipboardText`, and nothing in the tree states either way; the
  project-sets-a-CRLF-string path needs no such assumption.
- **Provenance:** pre-existing, and not `#77`'s. `string.lines` has always split
  on `'\n'` alone. Found by the cold peer review, 2026-09-01.
- **Not slugged** — no commitment to fix; the release does not depend on it, and
  no shipped example reads CRLF content.
- **Revisit:** with the `_update_cursor` pass below, if one happens — both are
  about the model's idea of what a line is. Note the fix is not obviously
  "split on `\r\n` too": stripping a lone `\r` is a content change, and whether
  the framework should silently rewrite what a project set is the same
  tolerance question D-CONTENT-NORM bounds.

### `_update_cursor` measures the column on the wrong line

- **Where:** `src/model/input/userInputModel.lua` — `UserInputModel:_update_cursor`.
- **State:** it sets `cursor.c` from `t[cl]`, the line the caret was on
  *before* the change, and `cursor.l` to `#t`, the last line of the content
  *after* it. When those differ the result is a column measured on one line and
  reported against another, and it can be out of range: on
  `{'one','twotwo','xx'}` with the caret on line 2, it yields `(3, 7)` — line 3
  is `"xx"`, whose caret positions are `1..3`. Probed, not inferred.
- **The intent is not in doubt, and the function used to satisfy it.** Before
  multiline it read, in full:
  `self.cursor.c = utf8.len(t) + 1` over a string `self.entered` — *seat the
  caret at the end of the content*, which is exactly what `jump_end` now does
  for a line list. The multiline commit (`19351528`, 2023-07-17, *"add multiline
  input representation"*) rewrote it to index a list and **measured the wrong
  line**: to preserve the intent it needed `t[#t]`, the line `.l` is being set
  to, and it used `t[cl]`.
- **The empty `else` is not a missing feature**, though it reads like one. The
  pre-multiline version was `if destructive then … end` with no `else` at all;
  the migration wrote the no-op branch out longhand and left it empty. Nothing
  has ever depended on it, in any revision.
- **Why it is BACKLOG and not ACTIVE: nothing observes it today.** After
  that fix deleted the `set_text` call, two call sites remain and neither
  exposes the defect. `_set_text_line`'s is guarded by `if not keep_cursor` and
  all seven of its callers pass `true`, so it is unreachable. `clear_input`
  reaches it, but on empty content every line measures zero, so the wrong line
  cannot give a wrong answer — it lands at `(1,1)`, which is correct by
  accident rather than by construction.
- **Why it is still debt:** it is a trap with no warning sign. The first caller
  to pass `keep_cursor = false` to `_set_text_line`, or the first content change
  that leaves `clear_input` non-empty, gets an out-of-range cursor with no raise
  — and the function's name and privacy marker both suggest it is a settled
  primitive.
- **The mechanism is that it bypasses the validated path.** `move_cursor` is the
  model's checked mover: it rejects an out-of-range line or column, falling back
  to the previous value, and it measures the line length **on the line it is
  moving to**. `_update_cursor` writes `self.cursor.l` and `self.cursor.c` as
  raw fields instead, so nothing catches the mismatch. Routed through
  `move_cursor` the bad `(3,7)` above could not have been produced, which is the
  same statement as saying `jump_end` already does this correctly: it computes
  `#ent` and `ulen(ent[last_line]) + 1` from the *same* line and hands both to
  `move_cursor`.
- **There are three raw writers, not two, and the third is on a hot path**
  (found 2026-09-01 by cold peer review). `UserInputModel:insert_text_line`
  does `self.cursor.l = l + 1` unvalidated, and it is reached on every
  Shift+Enter (`UserInputModel:line_feed`) and by Ctrl+D duplicate-line
  (`userInputController.lua`, the `modify` handler in `_normal_mode_keys`) —
  where the other two are reached rarely or not at all. This strengthens the
  entry's disposition rather than weakening it: the population to review is
  three, one of them live on ordinary editing, so *"review the cursor writers"*
  is a bigger and better-justified pass than *"repair this body"*.
  (`UserInputModel:set_cursor` also replaces the whole `Cursor` with no check,
  but it takes a constructed `Cursor` rather than writing fields, so it is a
  different shape.)
- **The likelier disposition is not a repair at all: this is a partial,
  unvalidated duplicate of `jump_end`, and what wants reviewing is its USAGE.**
  Both exist to seat the caret at the end of the content — that is what
  `_update_cursor` did correctly when it was single-line, and it is what
  `jump_end` does now. `jump_end` computes `#ent` and
  `string.ulen(ent[last_line]) + 1` from the same line, routes both through
  the checked `move_cursor`, and finishes the job: it settles the selection and
  moves the visible range. `_update_cursor` derives half its answer from a
  different line, writes raw fields, and does neither. So the review to run is
  *"does each call site want `jump_end`?"* rather than *"is this body right?"*,
  and repairing `t[cl]` to `t[#t]` in place would leave a second way to do one
  thing — which is what D-CONTENT-NORM's structural half exists to stop.
- **It is not a drop-in swap, which is why this is a review and not an edit.**
  At `clear_input` — the only reachable call site — `jump_end` would land the
  caret identically at `(1,1)`, but it also calls `end_selection` and
  `visible:to_end()`. `clear_input` already calls `clear_selection()` just
  above, so the first is redundant rather than wrong; whether the visible-range
  reset is *wanted* on a clear is a real question and has not been checked.
  Answer it before swapping, not after.
- **The narrow repair stays on the table** — `t[#t]` for the column, one token
  — as the answer if the review finds a caller that genuinely wants a raw,
  unvalidated seat. Nothing today does.
- Either way it touches a shared model primitive rather than this feature's own
  surface, which is why it is not being decided inside `#77`.
- **Provenance:** pre-existing, and not this feature's. The slip is from 2023,
  three years before this branch, and `#77` neither introduced nor widened it —
  it only deleted the one call site that made the asymmetry visible.
- **Not slugged** — a slug is the commitment to fix, and whether this is fixed
  is not decided. Nothing user-visible depends on it.
- **Revisit:** a pure-refactoring pass over the cursor writers, not a bug fix
  (owner, 2026-09-01) — it does no harm unless another caller reaches it or the
  call sites change, so it waits for the pass that would review
  `_update_cursor` against `jump_end` and decide whether the first should exist
  at all. Marked at the site with a `DEBT:` comment so a reader of the code
  meets the entry rather than the bug.

### The error highlight compares a byte column against a character index

- **Where:** `src/view/input/userInputView.lua` — `ec = perr.c` is read off the
  parse error, and the draw loop that counts `tl = string.ulen(s)` compares its
  character index against it.
- **State:** the parser reports an error column as a byte offset
  (`model/lang/lua/parser.lua`, `get_error`, read out of metalua's message),
  while the loop that colours the line counts characters. On a line holding
  multi-byte content the byte column exceeds the character index it is compared
  with, so the error colouring starts further right than the error is. On ASCII
  the two coincide and it looks correct, which is why nobody has seen it.
- **Sibling, already fixed:** the same byte column reached the caret through
  `_apply_eval`, where the new character bound refused it outright and the caret
  stopped moving. That was a live regression and was fixed with a `char_col`
  conversion. This site is the other consumer of the same value, found by the
  same review.
- **Why it stands (owner ruling, 2026-08-31):** deferred past this feature's
  release. It is cosmetic — a wrong colour extent, never wrong content and never a crash —
  it reaches only the console and editor error display, and it is not the input
  API's surface. **No slug**, by the convention that a slug is the commitment to
  fix.
- **What the guide promises, and why that promise still holds.** `../input_api.md`
  (*"Characters, not bytes"*) says *"every cursor position the widget reports or
  accepts is counted this way"*. The sprint's peer review read that as
  over-reaching, on the argument that an error column is a position the widget
  accepts. It is not one: `ec`/`el` reach `userInputView` only to choose a
  colour, and no project-facing call reports or accepts them — `get_cursor`,
  `set_cursor` and `show{cursor}` are the whole surface the sentence governs,
  and all three now count characters. The sentence stands as written; it is
  recorded here because the reasoning is not obvious from either document and
  the next reader will otherwise re-open the question.
- **Shape when taken:** reuse `char_col` (`model/input/userInputModel.lua`), or
  lift it where the model and the view can both call it. Do not fix the view
  alone — the unit should be settled once, at the boundary where the parser's
  answer enters the input subsystem, rather than at each consumer.
- **Revisit:** when the error display is next touched, or if mis-coloured errors
  are reported on non-ASCII source.

### D-ROUTE-OWNS — console/editor convergence onto the shared chain is unimplemented

- **Where:** `src/controller/consoleController.lua` (`ConsoleController:keypressed`,
  `:1516`) and `src/controller/editorController.lua`
  (`EditorController:keypressed`, `:825`) — each still runs its own narrow,
  single-argument dispatch, not the project route's `dispatch(shortcuts, hooks,
  widget, event, trigger, ...)` chain.
- **State:** D-ROUTE-OWNS (`../decisions/input.md`) names this convergence as
  "deliberately left as a follow-on, not attempted," and D-LOVE-ARGS and
  D-EXACT-RESERVE repeat the same scope note in different words. The decision text
  is honest about the gap; the gap itself is still open.
- **Why it stands:** out of this feature's mandate — scoped out on filing, not
  an oversight found later.
- **Revisit:** when the console/editor routes are migrated onto the combo
  mechanism. See also "Console and editor route handlers bind by hand-written
  modifier tests," which is this gap's symptom one layer down.
- **Release scope:** BACKLOG, not ACTIVE — the decision itself calls the convergence a
  deliberate follow-on, so it is deferred past this feature's release by the ruling that created it.
  Re-sorted 2026-08-27 by the ledger cross-check that every ACTIVE entry needs a roadmap row: it
  was the one ACTIVE entry without one, and the absence was the symptom, not the cause.

### Widget sink reaches the singleton via `love.state` global + nil-guard (RESOLVED-IN-PART by the input-API redesign)

- **Where:** was `src/controller/projectInputController.lua`, `_sink` — read
  `love.state.user_input_controller` on each call and guarded it with
  `if ui then …`.
- **Old state:** The old tier-4 `_sink` reached the widget through a global
  rather than an injected instance field (`self.input`), and defended with
  a nil-check against a value the singleton convention said was always
  present.
- **Resolution:** The sink is gone. `dispatch` (the free-function extraction
  recorded as an implementation note in `decisions/input.md`,
  `projectInputController.lua:74-86`) is now a free function that takes the
  widget as a parameter rather than reaching for a global itself — the
  concern moves one level up, to `ProjectInputController:_dispatch`
  (`:93-97`), which is the one remaining place that resolves
  `love.state.user_input_controller`. The nil-guard (`if widget and
  widget:is_shown()`) is carried at that boundary, not inside the reusable
  mechanism.
- **Revisit:** Whether `_dispatch` itself should inject `self.input` at
  construction instead of reading the global, and turn its nil-guard into
  an assertion, remains open — the same question, one layer up.

### The Web build has no coverage, and carried a feature-era regression unseen

- **State:** nothing in `busted tests` exercises the `_G.web` branch. A
  defect reachable only on the Web build is therefore invisible to every
  check this project runs.
- **The suite runs on whatever interpreter the developer's `busted` uses**
  (amended 2026-08-28) — on the owner's machine that is PUC Lua 5.1. That is
  how the retired `wrap` arity defect surfaced. The lint proposed below would
  not have caught it either: the call was not bare, it was on the guarded
  branch. A second interpreter in CI remains the only check that would.
- **The worked example, found 2026-08-03:** the dispatch chain introduced by
  `56c4284f` wrapped project keyboard handlers in a bare
  `xpcall(fn, handler, unpack(args))`, with no web branch. On PUC Lua 5.1 —
  what the Web build runs — `xpcall` drops the trailing arguments, so every
  adopted `love.keypressed` / `textinput` / `keyreleased` would have been
  called with nil for `key`, the held-key view and `isrepeat`. Before the
  feature there was exactly one `xpcall` in `controller.lua`, inside
  `wrap`'s guarded branch; the feature added a second, unguarded one. The
  wrapper collapse (`f1dc6aee`) removed it again, so the count is back to one
  — the regression is fixed, but it lived undetected for the whole feature
  because no check could see it.
- **Why it stands:** running the suite against PUC Lua 5.1, or building and
  driving love.js in CI, is infrastructure this project does not have, and
  neither is in this feature's scope.
- **Shape:** cheapest useful step is a lint or a review checklist item — no
  bare `xpcall` with arguments in `src/`; argument-forwarding goes through
  `wrap`. A grep is enough to enforce it and would have caught this.
- **Revisit:** if a Web build is released, or when CI grows a second
  interpreter.

### A project that raises leaves global device state dirty; no force-reset exists

- **State:** the sandbox deep-clones the `love` table but shares leaf C
  functions, so a project's imperative `love.*` calls — `setKeyRepeat`,
  `setTextInput`, `setRelativeMode`, raw audio — mutate real SDL/LÖVE state.
  The only mechanism that restores any of it is the project's own
  `compy.before_exit`, and by ratified contract that hook fires on stop
  paths only; crash is explicitly out of its scope. A project that mutates
  global state in top-level code and then raises therefore never restores it:
  `run_project`'s failed-run branch drops to `project_open` without ever
  calling `stop_project_run`, so nothing fires and the dirty state bleeds
  into the next run. `examples/keyboard` is the canonical mutator — it calls
  `love.keyboard.setTextInput(true)` and `love.mouse.setRelativeMode(true)`
  at startup. *(`src/main.lua:297` is the platform's only `setKeyRepeat`
  caller, and it turns repeat on — not one of the project-side mutations
  this entry tracks.)*
- **Why it stands:** two separate rulings, both deliberate. The hook is scoped
  to stop paths by design — crash/hard-kill was called out as a later layer,
  not an oversight. Firing a *partially initialised* project's teardown was
  ruled against (owner, 2026-08-03): no proper start, no contract is expected
  to run. Resetting the slot is a different question and IS done — a dead
  project's hook must not survive to fire against the next project's state
  (fixed 2026-08-03, `226628ae`).
- **Shape:** a framework-owned force-reset of the global surfaces the
  sandbox shares, run on every run-ending path including the crash ones, and
  independent of `compy.before_exit` — a project that crashed cannot be
  trusted to clean up after itself, which is exactly why its own hook is the
  wrong instrument here.
- **Revisit:** owner ruled 2026-08-03 to record it and implement the
  force-reset later; revisit when that work is scheduled.
- **Interim state (2026-08-12):** the stop path is project-by-project until
  then. `examples/keyboard` now restores relative mode in its own
  `compy.before_exit` (P-18-05), which closes the leak for that project on
  every stop path and for no other. The framework-side question — should the
  platform tear down device modes a project changed, rather than trusting
  each project to — is the "Shape" bullet above, and is not answered by that
  fix. The example's comment asserted for months that *"the runner restores
  it on exit"*: a project author's reasonable assumption about a platform
  that in fact restores nothing.
- **Where it goes when built (2026-08-07):** `framework_before_exit`
  (`consoleController.lua`) is now the framework's own teardown function and
  the only caller of a project's hook (D-STOP-IS-FW). It is the seam this entry
  has been describing — a framework-owned step, adjacent to but independent of
  `compy.before_exit`. The crash path still does not reach it: it only
  re-seeds `before_exit` back to `default_before_exit` (uninstall without
  firing, `consoleController.lua`), deliberately, since a partially initialised
  project runs no teardown. There is no `reset_before_exit` function today —
  the re-seed is the reset. Wiring the force-reset means calling the framework
  half on the crash path too, which is a decision this entry does not pre-empt.

### `compy.before_exit` is a closure slot

- **Where:** `src/controller/consoleController.lua`, `get_compy_namespace` —
  `before_exit` is a metatable-intercepted upvalue rather than a field of the
  namespace table.
- **State:** `table.clone` copies with `pairs` and reuses the metatable by
  reference, so a closure-captured slot is invisible to the copy and every
  clone of the namespace shares one variable. `base_env.compy.before_exit` and
  `project_env.compy.before_exit` are therefore the same slot, permanently. A
  plain field would be deep-copied per clone instead.
- **Why it stands:** Nothing tests, documents or depends on the sharing, and
  the suite passes with a plain field — so on its own it reads accidental. But
  `compy.input` survives cloning by the *same* mechanism, so a plain field
  would make `before_exit` the odd member of the namespace, and the sharing may
  be load-bearing for a path not yet identified.
- **Revisit:** Decide whether the sharing is intended. If it is, say so where
  the slot is built; if not, a plain field is simpler. Evidence, with probe
  transcripts: the frozen-surface audit run during this feature's
  implementation.
- **Not to be confused with** the crashes fixed on 2026-08-07: the call site is
  now guarded against both an absent hook and a raising one, which is orthogonal
  to how the slot is stored.

### A truthy `hooks[event]` return silently disables `on_limit_reached`

- **Where:** `src/controller/projectInputController.lua` (the free-function
  `dispatch`) — `hooks[event]` runs before the widget; `userInputController.lua`
  (`emit_limit`) fires `on_limit_reached` only from inside the widget itself.
- **State:** A project that sets `compy.input.hooks.keypressed` (or the
  text/release siblings) and returns truthy consumes the event at the
  hooks step, so `dispatch` never reaches the widget and the widget's
  `on_limit_reached` callback never fires for that keystroke — no
  error, warning, or other signal marks the drop. Carried through the
  input-API redesign unchanged — renamed from the old tier-3/tier-4
  vocabulary to hooks/widget, but the underlying coupling is the same.
- **Why it stands:** The truthy-consume shape (decisions/input.md,
  D-CHAIN-OF-3) is working as designed; it just wasn't checked against
  this specific hooks/widget interaction. No dedicated guard exists.
- **Revisit:** Note the coupling wherever `on_limit_reached` is
  documented for project authors, or decide it needs a guard.

### A raise from project top-level and from a handler surface differently

- **Status:** owner ruled (2026-07-31) to leave the behaviour as-is and refer
  the question to stakeholders; recorded here with the options as ruled.
- **Where:** `consoleController.lua` `run_project` / `run_user_code` versus
  `controller.lua` `user_error_handler`.
- **State:** the same authoring error reaches the author two different ways,
  decided by which `pcall` catches it. Raised from top-level project code:
  `run_user_code`'s `pcall` returns, `run_project` prints `'Error: ' .. msg`
  and drops to `project_open` — one console line, the project still open,
  nothing else on screen. Raised from a `love.*` handler or hook: `wrap`
  → `user_error_handler` → `suspend_run(msg)` → the error window over the
  project's last frame.
- **Why it matters:** balloons (smoke report 5) passed a lifecycle callback
  inside `show{}`, which D-UNKNOWN-RAISES makes a raise. The raise printed its line
  and left the user "in a console that gave no signal they were still inside a
  project" — which is the failure mode D-UNKNOWN-RAISES's own rationale ("explicit
  failure mode") is meant to prevent.
- **Options:** (a) route a top-level raise through the same suspend/error
  window path as a handler raise — one failure surface for one class of
  failure; (b) keep the console line but make the state legible (name the open
  project and how to leave it); (c) leave as is. Recommended: (a) — the
  asymmetry is an accident of which `pcall` caught it, not a decision anyone
  took, and (b) preserves the accident while adding words to it.
- **Revisit:** AFTER the PR merges, not during its review (owner,
  2026-08-03). Deferred deliberately to keep the PR's scope to the
  stakeholders' ask, and to leave them room to contest the suggested fix —
  a glitch may have had a reason nobody here can see.

### `close_project` bypasses the run's exit path

- **Status:** open — needs one ruling, either way.
- **Where:** `consoleController.lua` `close_project`, reachable from a running
  project's own env and from the console during `inspect`.
- **State:** it sets `app_state = 'ready'` and returns. `stop_project_run` is
  never called, so `compy.before_exit` never fires and handler teardown never
  runs. `quit_project` does it correctly (stop, then close); the bare path does
  not. The widget half is now handled at the call site (it destroys its own
  widget) — the rest of the exit path is not.
- **Decide:** either `close_project` runs the normal exit path, or the
  omission is confirmed deliberate and the reason is written down here. It is
  currently neither, which is why this entry exists.
- **Revisit:** with the next change to project lifecycle.

### A raise at `project_open` is swallowed whole, so pen-and-paper projects report errors worse than any other kind

- **Status:** open — found while probing the dispatch path's nil-safety during
  the widget-lifetime work; not a feature regression, the gate below is
  verbatim at the PR base. Sibling of the entry above: same class (what the
  author sees depends on something they did not choose), different cause —
  there it is *which `pcall` caught it*, here it is *what `app_state` happened
  to be*.
- **Where:** `controller.lua` `user_error_handler` → `consoleController.lua`
  `suspend_run`, whose first act is `if love.state.app_state ~= 'running' then
  return end`.
- **State:** a raise inside a hook or a `love.*` handler reaches
  `user_error_handler`, which calls `suspend_run` — and `suspend_run` does
  nothing unless the app is in `'running'`. A non-blocking project settles
  in `'project_open'` and lives there (see "Input-only / pointer-only projects
  stay live in `project_open`"), so for that whole lifetime a raise produces
  no error window and no state change. The only trace is the console line
  `user_error_handler` prints afterwards, and in pen-and-paper mode the
  project's canvas is what the user is looking at.
- **Confirmed by probe, not by reading:** the same raise in the same hook sets
  `suspend_msg` while `'running'` and sets nothing at `'project_open'`.
- **Why it matters:** this is the class of project — `sapper` is the shipped
  example — whose *entire* logic runs in hooks. Every authoring error in the
  part of the program that does the work is invisible, while the same error in
  the same project's top-level code is not. The gate reads as a guard against
  suspending something that is not running; the projects it silences are
  running in every sense the author cares about.
- **Options:** (a) drop the `'running'` gate and let `suspend_run` fire from
  `'project_open'` too — needs a check that the snapshot/resume path is sane
  from that state; (b) leave the gate and give the `project_open` case its own
  surfacing; (c) leave as is. No recommendation yet: (a) is small but touches
  the suspend path, which is not this feature's territory.
- **Revisit:** with the entry above — same decision-maker, same session,
  after the PR merges. Both are pre-feature behaviour and neither belongs
  in the stakeholders' ask.

### The error lock is correct, documented, and hostile

- **Status:** owner ruled (2026-07-31): behaviour is pre-feature, so leave it;
  record the UX concern with options for stakeholder review.
- **Where:** `userInputController.lua` — while `model:has_error()` holds,
  `textinput` is dropped and `keypressed` is swallowed except Enter / Space /
  arrows, which clear the error.
- **State:** to a user this is a freeze with no stated exit. It is what
  smoke reports 1 (guess, "froze after entering a symbol") and 9 (valid,
  "entering '1' stops processing any input") describe. The error band itself
  IS rendered and, since the widget-paint fix, IS visible; nothing in it says
  which keys resume.
- **Pre-feature check (asked for at the ruling):** nothing to reproduce. At
  the PR base `3256aac` the same lock exists and is stricter — only Enter,
  Up and Down cleared it, where today's also accepts Left, Right and Space.
  The band's invisibility was equally pre-existing (same render path, same
  unpainted widget). The input API neither introduced the lock nor narrowed
  its exits; it widened them.
- **Not drift:** the widening is ratified behaviour, and it matches what the
  docs already claimed. The frozen design (`§10 Edge cases`) reads "input
  locked until acknowledged (Enter/Space/arrows)", and the widening landed
  under that AC — its commit message (`9bb6d29`) says "Widen the sink's
  has_error() lock-clear gate to Space/Left/Right." No other commit touches
  that key list, so this is not a side effect of the 2D cursor/limit work.
  Separately, `internals/user_input.md` described the exit set as "Enter,
  space, or arrow keys" at the PR base while the code did only Enter/Up/Down
  — the change aligned code with both the spec and the doc. Narrowing it now
  would be a design change to a frozen document, not a drift fix.
- **The quirk worth naming:** an arrow key *acknowledges* the error and is
  then swallowed — it does not also move the caret to the offending character,
  which is what a user pressing Left after "not allowed" is trying to do. And
  `keyreleased` clears on Space as well, so Space acknowledges twice
  (harmless, but the two handlers duplicate the rule).
- **Options:** (a) append a hint line to the rendered error band ("Enter or
  Space to continue") — smallest change, no semantics touched;
  (b) clear the error on the next `textinput`, which makes a rejected line
  silently editable and drops what the lock is for; (c) leave it documented
  only. Recommended: (a).
- **Revisit:** AFTER the PR merges, not during its review (owner,
  2026-08-03). Deferred deliberately to keep the PR's scope to the
  stakeholders' ask, and to leave them room to contest the suggested fix —
  a glitch may have had a reason nobody here can see.

### `repl` does not evaluate, and its name says it does

- **Status:** owner ruled (2026-07-31): behaviour is pre-feature, so keep it;
  record the UX concern for stakeholder review.
- **Where:** `src/examples/repl/main.lua`.
- **State:** the example prints each submitted line back — `on_text_entered`
  pipes lines to `print`, and the widget runs the plain-text evaluator
  (`InputEvalText`), which has no parser. `x = 2 + 3` returns the characters,
  not a binding.
- **Pre-feature check (asked for at the ruling):** the same. At `3256aac` the
  example is `r = user_input()` plus an update loop doing `input_text()` /
  `print(r())` — reprint, not evaluate. The migration preserved the behaviour
  exactly.
- **Why it is a concern anyway:** evaluating Lua and printing a result is what
  the console does, and until the two fixes of 2026-07-31 (a refused
  widget after a project stop, and a project widget that was never painted at all)
  a project's input surface was visually indistinguishable from the console —
  same input line, no signal. An author testing `repl` could reasonably
  believe it evaluated, having been typing at the console. Both causes are
  fixed, so the modes now look different; the name still promises a
  read-eval-print loop the example does not provide.
- **Options:** (a) make it evaluate — the project env already exposes `eval`,
  so it is one line in `on_text_entered`; (b) keep the echo and rename the
  example (`echo`); (c) keep both, documented as-is (today's state).
- **Revisit:** AFTER the PR merges, not during its review (owner,
  2026-08-03). Deferred deliberately to keep the PR's scope to the
  stakeholders' ask, and to leave them room to contest the suggested fix —
  a glitch may have had a reason nobody here can see.

### A widget shown from a key can receive that key's own echo

- **Status:** answered by a documented project idiom, not by a framework
  mechanism (owner, 2026-08-03) — `../../input_api.md`, *"Worked example: the trigger key
  echoes into the widget it showed"*, pinned by `tests/input/input_widget_control_spec.lua`, group
  *"the documented echo guard"*, and used by `src/examples/turtle`. A
  framework fix was implemented and then reverted (2026-08-01) because its
  design had never been ruled. What remains open is whether the framework
  should ever take this over; the entry stays for that question.
- **Where:** `src/controller/controller.lua` (the `keypressed` / `textinput` /
  `keyreleased` gateways) and `src/controller/userInputController.lua` (the
  show path and the three widget handlers).
- **State:** LÖVE delivers a `keypressed` and a `textinput` for one
  physical key and guarantees nothing about their order. A project that shows
  the widget from a key therefore races its own trigger: measured — show on
  `keypressed('i')`, and the `textinput('i')` of the same press lands in the
  field, so the widget is shown already containing `i`. Showing on
  `keyreleased` (what `examples/turtle` does) is safe only because the echo
  usually arrives first; with the `textinput` delivered last it fails
  identically.
- **Why a project cannot fix it for itself:** it would have to consume a
  `textinput` whose text it cannot derive from the key name (`space` → `" "`,
  `shift+i` → `"I"`, anything an IME emits), and every project that opens a
  widget from a key would re-implement it.
- **Options:** (a) seal the widget for the rest of the event batch that
  opened it, released at the start of `love.update` — order-independent and
  needs no key→text mapping, but it also swallows an unrelated key typed
  within the same frame and assumes the stock run loop is the only pump;
  (b) match the trigger key's echo specifically — narrower, but needs the
  key→text mapping (a) avoids; (c) arm only on `keypressed`, leaving
  open-on-`keyreleased` projects racing; (d) no framework change, and the API
  documents an idiom projects follow instead — the workable one being a
  paired shortcut: register the trigger on both channels, where
  `shortcuts.keypressed[combo]` opens and `shortcuts.textinput[combo]`
  swallows the echo and unregisters itself, re-armed by whatever closes the
  widget. Verified in both delivery orders. Its limit: the re-arm has no
  single home (Escape clears without hiding, and there is no close callback).
  *(It was also confined to bare combos; that half is
  gone — dispatch lower-cases the trigger, so a `shift+i` registration now
  matches the `"I"` echo. A modified trigger additionally needs the modifier
  still held when the echo lands, which that fix did not test.)*
- **Revisit:** a design pass on the run loop's event-batch guarantees — the
  choice between (a)–(d) turns on what the framework is willing to promise
  about batch boundaries, which is a design question, not a bug fix.

### Combo triggers are key-name-only; positional bindings have no vocabulary

- **Where:** `src/controller/controller.lua`, `combo_string` — a combo's
  trigger is the LÖVE key name, which is layout-dependent, and the
  scancode is discarded at the gateway (`set_love_keypressed`:
  `local function keypressed(k, _, isr)`), so it reaches neither the routes
  nor the dispatch chain.
- **State:** compy has both audiences and serves only one. *Mnemonic*
  bindings — `ctrl+s` for save, `examples/turtle`'s `i` for input — want the
  key name, because the user's keycap says S. *Positional* bindings — a
  game's WASD — want the scancode, because on AZERTY `w` bound by name lands
  under the player's little finger. LÖVE exposes both for exactly this
  reason; the input API exposes only the first.
- **Why it stands (owner ruling, 2026-08-03):** not now, and never as a
  swap — a swap fixes one audience by breaking the other. No layout
  complaint exists in the record; this is a hypothesis about non-QWERTY
  users, not a report from one. Any future answer is additive: a second
  registration vocabulary (`shortcuts.scancode.*`, or an `sc:` prefix inside
  the combo string), never a change to what an existing combo means.
- **Also note it cannot help the textinput channel at all:**
  `love.textinput(text)` carries no scancode — one string, the character
  produced after layout, modifiers and IME. So scancodes cannot unify the
  keyboard and text channels; they would widen the gap between them.
- **Cost, if it is ever taken:** threading the scancode from the gateway
  through `forward_*` and the routes to the chain, and a scancode-keyed held
  set — `combo_string` builds its modifier prefixes from key names, so a
  scancode combo would otherwise be a hybrid (modifiers by name, trigger by
  position).
- **Revisit:** when a project needs layout-independent positional keys.

### A keyboard-hooks-only project does not count as interactive

- **Where:** `src/controller/controller.lua`, `user_is_blocking()` /
  `user_is_interactive()`, consulted by `ConsoleController:run_project` after
  the project's top-level code runs.
- **State:** the route is kept when the project replaced `love.update` or
  `love.draw` (blocking), or when it has a widget or a pointer handler
  (interactive). Keyboard hooks are neither. So a project whose only
  interaction surface is `love.keypressed`/`keyreleased`/`textinput` — no
  draw, no update, no widget, no pointer — hands the keyboard back to the
  console. The hooks the framework captured for it (D-HOOKS-SEEDED) can
  never fire. `examples/keyboard` is *not* an instance: it defines
  `love.update` and `love.draw`, so it is blocking and keeps the route.
- **Why it stands:** hypothetical. No such project exists in the tree, and one
  would be invisible by construction — its only outputs would be sound or
  console text.
- **Revisit:** if a keyboard-only project appears, or when ruling (a)'s
  "interaction surface" definition is next revisited; the fix would be to
  count seeded hooks alongside the widget and pointer tests.

### `gui` is supportable as a modifier, and deliberately not supported

- **Disposition:** not a defect, and not deferred work. `gui` (super / cmd /
  win) is outside the modifier set by decision (`../decisions/input.md`,
  D-THREE-MODS), which carries the rationale: never requested, added only
  for symmetry with the table-driven builder D-ASK-THE-DEVICE dissolves.
  This entry exists so the option is discoverable from the debt side; the
  decision is the authority.
- **What it costs today:** nothing observable. No shipped project or example
  registers a `gui` combo. `gui+s` is refused at registration (it names two
  triggers, D-COMBO-SHAPE) and `lgui` is bindable as an ordinary trigger.
- **What re-adding takes:** a `gui()` accessor beside `ctrl()`/`alt()`/`shift()`
  in `src/util/key.lua`, the pair restored to `mod_triples` and the fold table,
  and the precedence list extended. Bounded and additive.
- **Revisit:** when a requirement asks for it — not for symmetry, which is
  what put it there the first time. Whether the answer is a modifier at all
  is the wider question in "Service keys have no special treatment" below;
  this entry states only what re-adding `gui` *as a modifier* would cost.

### Service keys have no special treatment: `capslock`, `tab`, `lgui`/`rgui`

- **Where:** `src/util/key.lua` — `Key.is_mod` recognises exactly the `ctrl`,
  `alt` and `shift` pairs, and the combo grammar (`split_combo`/`check_combo`)
  treats every other token as a trigger. Verified: no code outside
  `src/examples/` mentions `capslock` or `tab` at all, and `lgui`/`rgui`
  appear nowhere in the framework's own dispatch.
- **State:** these keys therefore bind and dispatch exactly like `a` or `f5`.
  Each of them is unlike an ordinary key on real hardware, in a different way:
  `capslock` carries a lock state the framework cannot query and whose release
  is not reliably delivered; `tab` is a traversal key that a UI layer may want
  to claim before a binding sees it; `lgui`/`rgui` are owned in part by the
  desktop environment, which may consume a chord before the app is told.
- **Why it stands:** nothing is broken by it, and nothing has needed it. No
  shipped project or example binds any of the three as anything but a plain
  key.
- **Why it is written down:** the framework has no vocabulary for this
  group — they are neither modifiers nor ordinary character keys, and the
  input model currently has only those two categories. That is the observation;
  the shape of any answer is deliberately left open.
- **Revisit:** worth one review, at no scheduled point. At least three
  directions are open and this entry favours none of them — widen the modifier
  set, keep it deliberately narrow (which is the standing position,
  `../decisions/input.md`, D-THREE-MODS), or introduce a distinct class for
  service keys with its own rules.

### The widget-handle shape test exercises a stub, not the real draw wiring

- **Where:** the `love.state.user_input` handle is asserted only for shape — that
  `love.state.user_input` is set and callable while the widget is shown
  (e.g. `tests/input/input_widget_callbacks_spec.lua`). The dedicated
  `overlay_spec.lua` that built an ad-hoc controller over a `draw`-only
  stub view was removed when the suite was re-authored; the gap below is
  what survived it, not the file.
- **State:** Guards against the handle being re-narrowed, but does not
  exercise the app's startup widget-instance wiring or the real
  draw wrapper `set_love_draw` installs in `controller.lua` — the exact path a
  past regression faulted at. Runtime spot-checks have covered that path
  manually; the automated suite has not.
- **Why it stands:** Driving that real draw wrapper from a unit
  test needs app-bootstrap wiring the input suite does not currently stand
  up.
- **Revisit:** When a change next touches the widget/dispatch wiring — add
  a test that drives the actual draw wrapper against the widget instance.

### `Esc` clears the input in place without hiding the terminal (turtle)

- **Where:** the turtle example's input surface; likely the controller's
  `cancel()` path (`userInputController.lua`).
- **State:** Pressing `Esc` empties the input buffer but leaves the
  terminal open. This is the opposite of the editor's own `Esc` behaviour
  (below), so the two surfaces disagree on what `Esc` means.
- **Why it stands:** Intent unverified; may be deliberate (clear-in-place
  to retype) or incidental.
- **Revisit:** Characterise the intended `Esc` semantics for the input
  surface and reconcile with the editor's behaviour; decide whether they
  should converge.

### Editor input buffer not cleared on Escape

- **Where:** the editor input buffer.
- **State:** After Escape in the editor, the buffer retains its content
  rather than emptying. A fix was believed to exist at one point but is not
  present in the current tree — may live elsewhere or may never have
  landed.
- **Why it stands:** Unconfirmed whether this is a regression or a
  missing fix; needs a history search before filing as a defect.
- **Revisit:** Search history for the believed fix; if genuinely absent and
  reproducible, file as a defect.

### tixy shift+click example-sequence behaviour unclear

- **Where:** the tixy example project, running.
- **State:** Shift+click is expected to advance through the built-in
  example sequence, but the intended order is not obvious from the UI and
  may not match expectations. Observed once; not reproduced or
  characterised.
- **Why it stands:** Uncharacterised; may be a UX wrinkle in the example
  rather than an input-API defect.
- **Revisit:** Investigate before the input surface is considered stable
  for project authors; characterise reproducibly, then decide defect vs.
  expected.

### Touch delivery is not black-box expressible today

- **Where:** `tests/input/input_routing_spec.lua` — the pointer
  exclusivity block carries `pending('touch reaches the active route')`.
- **State:** Both the widget's and the route's touch handlers are no-op
  TODO stubs, so touch delivery mutates no observable state anywhere; a
  delivery probe would have to spy on method names, which the suite's own
  conventions forbid.
- **Why it stands:** No observable seam exists until a touch consumer
  lands; carrying it `pending` keeps the gap visible without a mechanism
  spy.
- **Revisit:** Green the row when a real touch consumer is wired.

### maze's Lua-command path is not black-box characterizable

- **Where:** `src/examples/maze` — the project's own `ctrl_update` /
  Lua-command dispatch.
- **State:** This path is not exercised by the input contract suite
  without loading the full project; routing to the project route in
  general is covered by other tests, but maze's own command interpretation
  is not.
- **Why it stands:** Would need project-loading scaffolding the contract
  suite does not currently have.
- **Revisit:** When example-project behaviour is next characterised as a
  body of work.

### Test-fixture standup boilerplate / naming

- **Where:** `tests/helpers/input_fixture.lua` — the module-standup
  boilerplate and the `F` table name.
- **State:** Open question whether the standup should reference exact
  bootstrap lines directly or be wrapped in a named seam, and whether `F` /
  `compy_input`-style names risk confusion with the real `compy` namespace.
- **Why it stands:** Cosmetic/ergonomic; does not affect correctness or
  coverage.
- **Revisit:** If the fixture's standup grows harder to trace, or the
  naming causes real confusion, address opportunistically.

### Force-path "does not warn" coverage gap

- **Where:** the config-suppression warning test coverage
  (`tests/input/input_widget_control_spec.lua`, the `show(): activation and reset` group).
- **State:** The suite covers "a non-forced re-show while active warns
  once", but there is no explicit assertion that the sanctioned `force`
  override path warns zero times. That guarantee is the inverse of the
  kept row and is currently only implied, not directly pinned.
- **Why it stands:** Low risk; the warn-don't-swallow guarantee is still
  covered by the kept non-force row.
- **Revisit:** Restore an explicit force-path no-warn assertion if the
  reconfigure surface evolves and the boundary needs re-pinning.

### Editor sets its input-widget cursor outside the project cursor API

- **Where:** the editor sets the cursor inside its input widget via its
  own internal path; the project-facing cursor surface is
  `compy.input.get_cursor`/`set_cursor`.
- **State:** Two code paths can move the same widget cursor — the
  editor's internal one, and the project-facing API. Not a dropped
  requirement; the question is whether the editor's own cursor-setting
  should consolidate onto the public API or stay separate.
- **Why it stands:** An open consistency call with no forcing deadline.
- **Revisit:** When the cursor API surface is next touched — decide
  consolidate-vs-separate and record it.

### Untracked scratch examples call removed input globals

- **Where:** `src/vadexamples/{guess,repl,turtle,tixy,valid}/main.lua` (and
  their READMEs) — git-untracked, parallel to the shipped `src/examples/`
  tree.
- **State:** These still call `user_input()`/`input_text()`/`input_code()`/
  `write_to_input()`/`validated_input()`, globals that no longer exist;
  they will fail if ever run as-is.
- **Why it stands:** Not part of the shipped example set; nobody currently
  runs them.
- **Revisit:** Migrate or delete at will; not blocking anything.

### PROPOSAL: if event-sourced held state is ever needed, it belongs to the framework

- **Status:** owner's direction, 2026-08-11. Not a commitment, and explicitly not this
  release; recorded so that the day someone needs it, they do not each build their own.
- **The rule it follows from** (`../decisions/input.md`, D-USAGE-SHAPE.5): a project does not
  reconstruct "what is held" from `keypressed`/`keyreleased`, nor the mouse equivalent, unless it
  is a deliberate decision taken in awareness of the drift — virtual mutable state with no path
  back to the truth, wrong after a focus change or a processing hiccup, and silently so.
- **The shape, if the need is ever demonstrated.** One event-sourced view maintained
  centrally by the framework and exposed for reads to projects, so the bookkeeping, and its
  reconciliation problem, exist once rather than per project.
- **The constraint that matters most: it stays separate from the physical polling surface.** A
  reader must always know which question they are asking — *what the event stream says is held*,
  or *what the device says is held*. The two answers legitimately differ, and conflating them is
  the "two clocks" problem this feature spent its length removing (D-ASK-THE-DEVICE, *"what it
  withdraws"*). One surface answering both, or silently switching between them, would rebuild it
  under a new name.
- **What would have to be true first.** A real consumer that cannot be served by a device poll —
  which is *not* what the example corpus showed: every held-state read in it is a "right now"
  question the device answers. Until such a consumer exists, this stays a direction.

### PROPOSAL: `compy.input.keys`, a held-state surface that hides its implementation

- **Status:** owner's proposal, 2026-08-10. Not this release — recorded so the shape is not
  re-derived, and because it reframes a question this feature spent a long time on.
- **The shape.** A proxy table on the input surface answering *"is this key held"*:
  `compy.input.keys.h` resolves to `love.keyboard.isDown('h')`, and the foldable names —
  `keys.shift` / `keys.ctrl` / `keys.alt` — resolve to `Key.shift()` / `Key.ctrl()` /
  `Key.alt()`, so the left/right pair folds exactly as it does in a combo string. One vocabulary,
  read the same way from a handler and from `love.draw`.
- **Why it is worth having, in evidence rather than in principle.** Every input-heavy project
  re-derives this. The keyboard example built a proxy of exactly this shape twice — first over
  a mirror it maintained itself, then over the framework's tracked set. `maze` wrote
  `is_shift_down()` by hand, and `turtle`, `clock` and `sapper` each spell out
  `love.keyboard.isDown` or `Key.*` at their call sites. The convergence is the argument.
- **The property that matters most: it makes polling-versus-tracking an implementation detail.**
  Today it proxies straight to the device. If a mirror populated from `keypressed`/`keyreleased`
  is ever genuinely needed, it can be swapped in behind the same surface, transparently to
  every project — which is precisely what a bare `keys_pressed` table could not do, because the
  table *was* the contract. D-ASK-THE-DEVICE removed a model kept beside the device; this proposal
  removes the need to ever expose which one is in use.
- **Two optional extensions, later and only if a need appears:**
  - **An enumerator** — "list every key currently held". This is the one capability a device poll
    genuinely cannot provide (you can ask about a key, not for the set), and providing it centrally
    is cheaper than each project keeping its own bookkeeping to get it.
  - **`compy.states`, a writable surface** — a project registers an arbitrary state-polling
    function under a name and gets on/off callbacks at the transitions of that condition,
    centrally evaluated. That generalises the held-chord gap below from keys to any condition,
    and moves the evaluation loop out of project machinery into the framework.

    **[Owner's remark, 2026-08-10] This half is not an input mechanism and should not be scoped
    as one.** *"State-polling can be generally useful in a wider class of situations than just
    key-state queries."* The pattern it replaces — evaluate a predicate every frame, keep a
    boolean mirroring it, and act on the moments it flips — is what an input-heavy project
    happens to need most visibly. But nothing about it is specific to keys: a pointer entering a
    region, a value crossing a threshold, a game predicate becoming true are all the same shape,
    and each is written out by hand today with its own mirrored flag. That is why the owner named
    it `compy.states` rather than `compy.input.states`, and the naming should be read as the
    scoping decision it is. It also means the mirrored-flag bug class this sprint spent its
    length removing from the framework is, in projects, a general pattern with no vocabulary —
    the keys case is one instance of it, not the whole of it.
- **Design questions it would have to answer, named so they are not discovered late:**
  - **Name space.** `keys.shift` means the fold, but `lshift`/`rshift` are also real LÖVE key
    names — the surface must say which names are folds and which are keys, or the two collide.
  - **Silent nil.** A proxy that returns nothing for an unknown name turns a typo (`keys.shfit`)
    into "not held", with no error, in a value used directly in conditionals. A fixed key-name
    vocabulary exists, so raising on an unknown name is available and probably right.
  - **Property or call.** `keys.shift` reads as state, which is what makes it pleasant, and also
    what hides that each read is a device call.
- **Revisit:** when a project needs held-state vocabulary that today it must build for itself —
  which, on the evidence above, is most input-heavy projects. See also the entry below, whose
  on/off transition problem the `compy.states` half of this proposal is the general answer to.
- **CONDITION — this proposal carries something for another decision, and dropping it silently
  would leave that unanswered.** D-ASK-THE-DEVICE (`../decisions/input.md`) dissolved the framework's
  tracked held-key set. It was challenged on the ground that the biggest input-heavy example had
  *independently* grown a model of the same shape, which is evidence of an unmet need. The
  challenge was examined and the decision stands: what that example's model was actually reaching
  for was edge detection — answered by the `isrepeat` flag the API delivers, and its own fix
  reached for no held-state at all — plus foldable held-state convenience, which a stateless
  device poll answers and which this proposal is the durable answer to.
  So if this proposal is dropped, deferred indefinitely, or replaced by something that does not
  answer the convenience half, that convergence evidence stops being addressed and D-ASK-THE-DEVICE's
  standing should be re-examined at that point. Recorded here rather than in a review document
  because reviews are transient and this is the condition, not the argument.

### A chord that gates a state while it is held has no vocabulary

- **Where:** the shortcuts mechanism generally (`src/controller/projectInputController.lua`,
  `find_shortcut`; `src/controller/controller.lua`, `combo_string`), and
  `doc/input_api.md`, "Choosing the mechanism: transitions,
  state, and what not to build".
- **The rule this rests on, stated because the API does not state it (owner, 2026-08-10):**
  a combo can only reliably serve an atomic transition — a one-off shot, stateless in
  itself. It must not be used to toggle a long-lived state that depends on the combo still
  being held. The reason is mechanical, not stylistic: a combo is serialised from its
  trigger plus the modifiers held at that instant. So the event that would *end* the
  state may serialise differently from the one that began it, and the ending binding is
  simply missed.
- **The two ways it bites, both real:**
  - *A modifier released first.* `keypressed['alt+h']` sets a flag; the player lets go of Alt
    before `h`, so `keyreleased('h')` serialises as plain `'h'` and the `'alt+h'` binding never
    fires. **No second binding closes it** — a modifier's own release has no expressible combo
    at all (D-COMBO-SHAPE: one trigger, so `'alt+lalt'` and bare `'lalt'` both raise).
  - *An unrelated modifier pressed mid-hold.* The guide's own flag example binds bare
    `'space'` on both channels; press Space, then press Ctrl, then release Space, and the
    release serialises as `'ctrl+space'`, missing the `'space'` clearing binding. **The
    documented pattern has the defect it is documented to solve.**
  - Both leak the same way on focus loss, where no release is delivered at all.
- **What is missing, sketched (owner, 2026-08-10):** an abstraction for *"this chord is
  currently held"* — evaluated on update, with two callbacks, on and off, fired when the
  condition starts and stops being true. Machinery and syntax could mirror shortcuts; only the
  integration differs — instead of one callback on an event channel, a pair on a transition of
  a *condition*. It would replace held-state `if` cascades sprawling through project code, and
  the same shape serves *"Ctrl held during a drag"*, which today every project re-derives.
- **Why it stands:** not this release. It is new API surface, and the feature's mandate is a
  simpler and more robust input API, not a larger one. Recorded so the idea is not re-derived,
  and so the rule above is available to anyone reaching for a combo to hold a state.
- **Revisit:** when a project needs held-chord state and the honest answer is still a poll —
  which is what the keyboard example's help overlay does today, deliberately.

### sapper's modifier click path is a touch fallback, and converting it needs the platform's help (RESOLVED, 2026-09-14)

- **Resolved:** the sapper example left this repository. Sapper ships from
  <https://github.com/dsent/compy.sapper>.
- **Where:** `src/examples/sapper/main.lua` — the two guarded click hooks and `love.mousepressed`.
- **What it is.** Shift+press flags and Ctrl+press unlocks, each guarded as *this modifier and
  none of the other two*; the plain click hooks act only when nothing is held. **Its purpose is
  the timing** (author, 2026-08-10): on touch devices a single tap is often accidental and a
  double tap unreliable, so the modifier-held press is the dependable route to both actions.
  That rationale is not written in the code, and its absence already caused one wrong change.
- **The obvious conversion is wrong, and was made and reverted (2026-08-10).** Moving the two
  variants to `shortcuts.singleclick['shift+*']` / `['ctrl+*']` is faithful to the *shape* — a
  class key means exactly "this modifier set and no other" — and destroys the *purpose*: derived
  clicks are button 1 only, counted on release, resolved only after the double-click window, and
  discarded if the pointer drifts, which is the mechanism the press path exists to bypass.
- **What a correct conversion looks like, and the hole it still has.** Keep the press path as
  `shortcuts.mousepressed['shift+*']` / `['ctrl+*']` — on a channel *with* a trigger the class key
  falls back correctly, so this reproduces "any button, at press time" exactly. Then swallow the
  derived echo with `shortcuts.singleclick['shift+*'] = fn.stop_here()`, because consuming a
  press does not prevent the derived click: the gateway counts clicks in its own
  `mousereleased` handler, before and regardless of anything the project consumed.
  **The residual hole:** a derived click's modifiers are sampled at synthesis time, after the
  double-click window — so releasing the modifier during that window makes the echo serialise
  unmodified, miss the swallow, reach the plain hook, and act a second time. On a touch device,
  where the modifier is a key held in the other hand, that is a realistic sequence.
- **The hole is already in the shipped example, not a property of any conversion**
  (verified 2026-08-11). Shift+press flags the cell immediately; the gateway synthesises the
  single click 0.4 s later (`controller.lua`, `click_delay`); if Shift is released inside that
  window the derived click serialises with no modifiers, passes the hook's own *"nothing
  held"* guard, and runs the action a second time. Because flagging toggles
  (`actionFlag` → `flowToggleFlag`), the second run un-flags the cell. **Net effect:** shift-click
  appears to do nothing if the player lets go of Shift promptly — a live,
  user-visible defect in the example as written, predating this feature entirely.
- **Ruling, 2026-08-15:** retain the fallback. The rare delayed echo is
  accepted without a project-side guard: the damage is negligible and a flag
  would add more machinery than it removes.
- **Revisit:** only if user reports show the echo is material. A platform
  change preserving the originating press's modifiers remains outside this
  feature's scope.

### Modified shortcut families need explicit fall-through policy

- **Where:** project `compy.input.shortcuts` beside ordinary hooks or captured
  `love.keypressed` / `love.textinput` handlers.
- **State:** shortcuts match one exact modifier set. A project that wants a
  shortcut family to claim every modified form must register every meaningful
  and meaningless combination; otherwise an unclaimed combination reaches its
  ordinary keyboard or text-input handling.
- **Why it stands:** the explicit registrations make every claimed combo
  visible, but example grooming has shown that redundant no-op combinations
  quickly become noise.
- **Revisit:** after embedded-example grooming. Evaluate an opt-in wrapper
  such as `compy.input.fn.if_no_modkeys(fn)` that suppresses an event whenever
  a modifier is held, against the risk of hiding a deliberately modified input.

### Examples are not onboarded onto the new input API

- **Where:** `src/examples/{maze,keyboard,turtle,clock}` — the sites listed
  below. The three detached repos (`keyboard`, `maze`, `balloons`) have
  their own remotes and no test suite; `balloons` reads no held state at
  all and appears nowhere here.
- **State:** The examples were reconciled with the removal of the tracked
  held-key set and with the guide's recommendation ladder
  (`doc/input_api.md`, "Held keys"): every read now sits at a rung that is
  correct rather than one that is gone. Several of them are still a rung
  below the one the API offers — a poll answering a question `shortcuts`
  answers directly, or a modifier test that is a combo written out. Each
  conversion below was considered and declined during the reconciliation
  because it is a behaviour change, a control-flow restructure, or both, in
  a repo where the only gate is running the app by hand.
- **The sites, and what each would become:**
  - `maze/main.lua:568` — `k == "escape" and not Key.shift()` inside
    `love.keypressed` is two bindings: Shift+Escape quits, bare Escape is
    ignored. The combo form moves `escape` out of `SYSTEM_KEYS` and depends
    on shortcut-before-hook ordering.
  - `maze/main.lua:514-526` — `poll_tab_progression` polls `tab` every
    frame and keeps a `tab_was_down` mirror to derive an edge;
    `shortcuts.keypressed['tab']` is the edge. It also carries the bug
    class the platform just removed: a flag mirroring a key, with nothing
    to reconcile it. The edge feeds two different actions depending on
    game state, so the restructure is not a one-liner. **A bare-key combo
    is legal** — modifiers are optional and only a bare `'*'` is refused —
    **but it narrows the trigger, and that is a behaviour change to state
    rather than discover.** The poll fires on Tab whatever else is held;
    a `'tab'` binding is an exact match on the serialised combo, so
    Ctrl+Tab and Shift+Tab serialise as `'ctrl+tab'` / `'shift+tab'`,
    miss it, and fall through to the hook. Probably an improvement here —
    a stray modified Tab should not skip a level — but it is a decision,
    not a detail.
  - `maze/macro.lua:74,89` — `macro_state.shift_held` is a held-modifier
    mirror maintained across `keypressed`/`keyreleased`, the same shape.
    **Listed by adjacency, not by the same trigger as the rest:** it reads
    no device and never touched the framework's set — the flag is set from
    the event's own key name against a static table (`SHIFT_KEYS`) — so it
    was outside the reconciliation's mandate and is here because it is the
    pattern that mandate kept meeting. It is also not a pure read: the
    release runs `finish_recording()`, so replacing the mirror with
    `Key.shift()` is not behaviour-preserving on its own.
  - `keyboard/alt.lua:203` — `k == "h" and INPUT.ctrl and INPUT.alt`
    hand-matches the combo its own comment calls "Ctrl+Alt+H". Its natural
    form is a shortcut registration; the scene's key routing is what the
    `textinput` heal rewrites, so it waits for that.
  - ~~`keyboard/help.lua:16-19`~~ — **RESOLVED 2026-08-11: the poll is
    correct and stays.** This entry previously called the flag-shortcut shape
    its top rung; the usage principles invert that. The overlay is up while a
    chord is *held*, which is continuous state, and a mirrored
    press/release pair cannot close reliably here at all — a modifier's own
    release has no bindable combo. See `doc/input_api.md`, "Choosing the
    mechanism".
  - `keyboard/input.lua:109` — `isMod` re-implements `Key.is_mod`. Not a
    held-state read, so outside the reconciliation's sweep, but the same
    duplication: it is used in `alt.lua`, `findkey.lua` and `hunt.lua`.
  - `turtle/main.lua:34` — `Key.shift()` inside `love.keypressed` guards
    `shift+r`. It remains because turtle demonstrates captured callbacks.
  - ~~`clock/main.lua:69,78`~~ — **RESOLVED 2026-08-11 by deciding not to
    convert, with the reason written into the file.** `space`,
    `shift+space` and `shift+r` name themselves like combos, but a
    shortcut matches its modifier set exactly, so a `'space'` binding
    would stop firing while any unrelated modifier is held, where the
    hook fires regardless. The narrowing is invisible in the diff that
    would introduce it and nobody asked for it.
- **Why it stands:** Deliberate scope. The reconciliation's mandate was two
  named platform changes; converting an example to the API's better shape is
  a different job, and doing both at once turns a reconciliation into a
  rewrite. Nothing here is broken — each site works as written.
- **Revisit:** This section is the work list for the example onboarding work
  that follows, which reads it entry by entry. That work is split by weight:
  the in-repo examples are a sweep, while `keyboard` and `maze` each get their
  own pass, since each holds conversions that need planning rather than
  applying. A site may be declined again with
  fuller reasoning; what it may not do is disappear silently.

### `compy.input` is built once for the application, not per project run

- **Where:** `src/controller/consoleController.lua` — `get_compy_input()` runs
  inside `prepare_project_env`, which `ConsoleController.new` calls once, at
  construction. Every project run therefore shares one surface and one private
  `state`. Env cloning does not separate them either: `table.clone` copies the
  surface's metatable, and that metatable closes over the same `state`.
- **Corrected 2026-08-26.** The earlier premise — that `compy.input` is rebuilt per
  project run — was wrong, and is what made an application-lifetime store look
  run-scoped: that is how the hidden-`configure` draft came to survive a project
  stop (fixed; see `internals/user_input.md`, *`configure(config)` — the
  live-reconfigure surface*).
- **Disposition:** Accepted, no action expected — but for a different reason than
  the one recorded before. The `show`/`hide` closures resolve the live widget at
  call time, so a build-once surface still reaches the current widget. What the
  arrangement costs is that every store the closure owns outlives every
  project, so anything run-scoped must live on the widget (where teardown
  reaches it) rather than in `state`. `callbacks` and `pending` both do;
  `shortcuts` and `hooks` are wiped by name at teardown instead.
- **Revisit:** if a third run-scoped store is ever added here, prefer moving the
  whole `state` to a per-run lifetime over adding a third teardown arrangement.

### Console debug hotkeys are ad-hoc `if`-navigation

- **Where:** `src/controller/controller.lua`, `set_love_keypressed` — the
  `Ctrl+Shift+<n>` / `Ctrl+Alt+d` debug toggles are a nest of `if k == …`
  branches ahead of the route forward.
- **State:** These branches are exactly the shape combos exist to replace —
  falsey-return, fall-through participants keyed on a serialised combo. They
  predate the combo mechanism and were left in place.
- **Why it stands:** Cosmetic; the branches work and run only under
  `love.DEBUG`. Not worth a behavioural change on its own.
- **Revisit:** When this handler is next touched — lift the debug toggles
  onto the combo-table mechanism (D-COMBO-TABLES), or a `toggle_debug(k)` helper.

### Per-event `set_love_*` installers are lexically isomorphic

- **Where:** `src/controller/controller.lua`, `set_default_handlers` — ten
  near-identical `Controller.set_love_<event>(CC)` calls, each backed by an
  equally near-identical `set_love_<event>` installer.
- **State:** The installers differ only by event name; the repetition invites
  a table of per-event entries driven by one iterator. Flagged inline as a
  code-hygiene concern, not a correctness one.
- **Why it stands:** The explicit form is readable and predates this note;
  collapsing it is a refactor with no behavioural payoff.
- **Revisit:** If the installer set grows or is next restructured — drive it
  from a `{ event → installer }` table.

### Discovered, de-facto behaviours pinned during the un-fork (rationale note)

The un-fork's preservation tests froze several behaviours that are not designed
contracts but were discovered as existing behaviour with no mandate to alter
— treated as de-facto standards per the implementation and pinned so they can't
be silently narrowed later (any change is a separate, owner-gated decision):

- **Non-shift Enter submits** — Ctrl+Enter and Alt+Enter submit, not only bare
  Enter (guard is `is_enter and not shift`; also consistent with
  `doc/development/decisions/input.md` D-EDIT-LIFECYCLE). Pinned for widget + console.
- **`SearchController:keypressed` returns a jump target** (`{block, line}`) up its
  caller on Enter — the same "keypress return carries a domain result" shape the
  shared widget's limit-flag return was retired for (D-EDIT-CALLBACKS). Left as
  is because `SearchController` is a different class, out of scope here.
- **The project widget's view skips the per-frame `update_view()` workaround by
  widget *identity*** (`userInputView.lua:draw`, `self.controller ~=
  love.state.user_input_controller`) — an identity check standing in for the old
  `oneshot` flag. Its survival under a console/editor re-plug remains a
  tracked future concern, out of the input API's scope.

### paint's `useCanvas(btn)` means a mouse button on one path and a click count on the other (pre-existing; RESOLVED, 2026-09-14)

**Resolved:** the paint example left this repository. The Paint that ships with
Compy is a different program, <https://github.com/dsent/compy.paint>.

`src/examples/paint/main.lua` calls `useCanvas(x, y, btn)` from two places, and `btn` means
something different in each:

- **the drag path** — `compy.input.hooks.mousemoved` polls `love.mouse.isDown(btn)` for `btn = 1, 2` and
  passes the held button through. Here `btn` is a real LÖVE mouse button.
- **the click path** — `point(x, y, btn)`, reached from `hooks.singleclick` and
  `hooks.doubleclick`. Here the number is paint's own action selector, written as a literal
  in each binding: `1` for the primary gesture, `2` for the secondary. The framework passes
  the two hooks `(x, y)` and nothing else — no button, no count — so nothing hands paint a `2`
  to misread. Paint picks it.

So the function reads as button-aware, and half its callers cannot supply a button.

**This is not a case of a receiver misinterpreting a value it was sent** — the question is
worth stating because the coincidence invites it. `doubleclick` does not deliver "button 2";
it delivers `(x, y)`, and paint's handler body chooses to call the secondary action `2`. Had
the framework been passing a click count into a button parameter, that would be a defect; it
never did, at the PR base or now. What is left is a latent trap: one parameter, a real LÖVE
button on the drag path and a hand-picked constant on the click path, with the two meanings
agreeing by luck (`2` = "secondary" in both readings). The
consequences a user meets: right-drag on the canvas paints with the background colour,
right-click does nothing, and double-click paints with the background colour. One effect,
two unrelated gestures, plus a third gesture that looks like it should work and does not. The
same conflation runs through `setColor`, whose `btn > 1` branch is reachable only by double
click, so "secondary colour" is bound to double-click rather than to the secondary button.

**Pre-existing, not a migration artefact.** At the PR base (`3256aac`) the drag path is
byte-identical and the click path bound `compy.singleclick` / `compy.doubleclick` with the same
hardcoded 1 and 2. This feature renamed the bindings (`compy.X` →
`compy.input.hooks.X`) and changed nothing about the meaning.

**Why it cannot simply be fixed by binding the button.** The derived clicks name no button by
ratified decision (`../decisions/input.md`, D-BUTTON-TRIGGER, "The derived clicks keep `(x, y)` and
name no button"): they are not LÖVE events and the click timer synthesises them from
left-button releases only. A project that needs to know which button produced a click binds
`mousereleased` and does its own timing — which is exactly what the framework's timer does on
the project's behalf for the left button.

**Ruled not to change paint (owner, 2026-08-07):** the example never intended a secondary-button
gesture, secondary-button availability is not uniform across environments, and mapping the
secondary action onto a double-click may well be deliberate. Recorded because the parameter's
double meaning is a trap for the next person to edit this example, not because the behaviour is
wrong today.

**Recommendation, for whenever paint is next opened.** Nothing here is urgent — the example
works, and this is about how easy it is to keep working.

1. **Name the two layers.** `1` and `2` appear as bare literals in the two click bindings and
   again as branch conditions in `setColor` and `useCanvas`, so the meaning lives in the
   reader's head rather than in the code. `local FOREGROUND, BACKGROUND = 1, 2` — or better, a
   value that cannot be confused with a button at all, such as the strings `'fg'` / `'bg'` —
   makes each site say what it does. This is the cheap half and it removes most of the risk on
   its own.
2. **Stop using a button number as the layer identifier.** Even named, `btn` is fragile
   precisely because one of its two call paths really is a LÖVE button: a future edit that
   passes a genuine `3` (middle click) or that reads `btn` as a button on the click path will
   be wrong in a way nothing catches. Splitting the parameter — the drag path translating the
   held button into a layer before calling — keeps the button at the edge, where it belongs.
3. **A modifier may be the better metaphor for "background".** Ctrl-draw or Alt-draw is a
   conventional secondary-action gesture, it reads the same on a trackpad and on hardware with
   no reliable second button, and the input API expresses it directly:
   `shortcuts.mousepressed['ctrl+mouse1']` is a ctrl-click and `shortcuts.mousemoved['ctrl+*']`
   a ctrl-drag (`../decisions/input.md`, D-BUTTON-TRIGGER). That would also let double-click go back
   to meaning something double-click-shaped, instead of standing in for a button paint cannot
   observe.

Points 1 and 3 are independent: naming the layers is worth doing even if the gesture never
changes.

### A modifier accessor answers truthy/falsy, not a boolean

- **Where:** `src/util/key.lua` — `ctrl`/`alt`/`shift` return
  `love.keyboard.isDown(...)` straight through, and are annotated
  `@return boolean`. Real LÖVE honours that; the annotation is not enforced
  for anything that replaces `isDown`.
- **The one known offender is fixed (2026-08-16).** Harmony's lock-mode patch
  used to fall off its own end for an unheld key, returning no value rather
  than `false`, and Lua adjusts that to `nil` at a call site. It now returns a
  boolean on every path (`src/harmony/init.lua`, `patch_isDown`), on the ground
  that a mock matches the signature of the thing it mocks. What remains is the
  general exposure below, not a live instance.
- **State:** harmless to every `if Key.ctrl() then` in the tree, since `nil` and
  `false` are both falsy. It bites the moment a device read is compared
  rather than tested: `Key.ctrl() == false` is `false` under harmony, and
  `Key.ctrl()` spliced as a call's last argument contributes no argument at
  all. The live exposure is the second, at six call sites that pass a modifier
  read as a trailing argument (`editorController.lua:466,470,772,776`,
  `searchController.lua:101,105`), none of which is affected today because the
  callee only tests the value for truthiness. The comparison form was observed
  once, in the gate's `only_mods` helper, which normalised with `not not`; that
  helper no longer exists (D-RESERVE-TABLE replaced the predicate cascade with a
  combo-string table), so no site in the tree compares a modifier read today.
- **Why it stands:** nothing is wrong under a real device, no patcher offends
  today, and no caller compares. Changing the accessors is a small edit with a
  wide blast radius — every caller's return type would become guaranteed, which
  is desirable but wants its own pass and its own tests.
- **Shape, if it is answered:** normalise inside `Key` — `return not not
  love.keyboard.isDown(...)` in each of the three accessors — so the
  `@return boolean` annotation becomes true for every consumer, and no future
  caller has to remember `not not` to compare safely.
- **Revisit:** when `Key`'s accessors are next touched, or the first time a site
  compares a modifier read rather than testing it.

### Console and editor route handlers bind by hand-written modifier tests

- **Where:** `editorController.lua` (~33 tests), `searchController.lua` (5) and
  `consoleController.lua` (4) — `if Key.ctrl() and not Key.shift() and not
  Key.alt() and Key.is_enter(k)`, and the same shape for Escape, paste, scroll
  and the debug toggles. Six further reads are not this debt: `_scroll('up',
  Key.ctrl())` passes a held modifier as continuous state, which D-USAGE-SHAPE
  rules correct.
- **State:** these are combos written the long way, at the one layer the feature
  did not convert. Two costs, and the second is the live one:
  - **Nothing can list them.** A combo table is enumerable — that is why the
    input guide can print what the platform reserves. A cascade of `if`s can
    only be read.
  - **Each test claims every modifier it does not name.** The editor's `load()`
    tests Ctrl and Shift but not Alt, so Alt+Escape loads the selection; the
    console's `if Key.ctrl() then if k == "l"` makes Ctrl+Shift+L and
    Ctrl+Alt+L clear the output. This is exactly the tolerance D-EXACT-RESERVE
    outlawed for the pre-dispatch gate, still present one layer down — and the
    same handlers write the exact form (`not Key.shift() and not Key.alt()`)
    elsewhere, so the inconsistency is within a single file.
- **Why it stands:** no project competes for these keys — the console owns the
  route precisely when no project runs — so nothing is broken today, and
  D-EXACT-RESERVE's scope clause deliberately left this layer out. It is soft debt:
  a consistency and legibility cost, not a defect.
- **Shape, if it is answered:** register these as combo tables on the
  controllers, the way a project registers its own. That is the console/editor
  adoption D-ROUTE-OWNS defers, and it subsumes the debug-toggle entry above.
- **Revisit:** with the console/editor migration, or the first time one of these
  handlers has to state what it claims — a tolerant test is invisible until a
  chord that extends it is wanted.

### A gesture that tolerates a modifier costs one registration per variant

- **Where:** `compy.input.shortcuts` and the combo grammar (`src/util/key.lua`,
  `split_combo`/`check_combo`). A combo is its modifier set exactly
  (D-COMBO-SHAPE), and the `'*'` class key is a class of one modifier set too —
  `'alt+*'` does not match `alt+shift+key`.
- **State:** a project that wants *"Ctrl+Alt+Up, and I do not care whether
  Shift is also down"* must register `ctrl+alt+up` and
  `ctrl+alt+shift+up`. `examples/keyboard` needs six such tolerant gestures
  and pays twelve registrations for them (`input.lua`,
  `register_reserved`). Nothing is broken by this and every binding is
  explicit, which is the model's virtue.
- **Why it is written down (2026-08-12):** the cost is not the typing, it is
  that *a missing variant is silent and looks exactly like the code being
  right*. Converting this one example's hand-written modifier tests to combos
  dropped six gestures; four were caught by one cold review, the fifth by
  a second, and the sixth by a third — each time after a fix for the previous
  one had been written by someone who had just read the rule and the bindings
  together. That is three independent reviews to converge on one file's
  twelve lines, and the register should say so before the next project
  migrates.
- **Shape, if it is ever answered:** a tolerance marker in the combo grammar
  (something like `'ctrl+alt+shift?+up'`), or a registration helper that
  expands one gesture into its variants. **Neither is proposed here** — the
  explicitness of the current model is a deliberate property and a tolerance
  syntax trades it away.
- **Revisit:** when a second project hits it, or when the input guide gains
  its reserved-combo section (P10) and has to explain the double binding
  anyway.

## RETIRED

### T-BLOCK-AT-OPEN — the editor's opening selection moved, now recorded (RESOLVED, 2026-09-18)

**RESOLVED 2026-09-18 (session104): the record is written.** The behaviour is
stated in `../internals/editor.md` (*"Content Types and Buffer Initialization"* — the editor
opens on the first block, changed from the last with the PR #45 import), and a user-facing line
is in `CHANGELOG.md` (`CURRENT_SCOPE`, *Changed*). The guide predicted nothing about the old
selection, so it needed no edit. **Kept rather than vacuumed:** the change is upstream's and
shipped, so this entry is the evidence behind the changelog line (`ledgers.md` §3), not an
introduced-in-branch draft. The original analysis follows, unchanged.


- **Where:** the editor's opening path — `src/model/editor/bufferModel.lua`, which our merge took
  from upstream PR #45 whole (`git diff f4cf338c HEAD -- src/model/editor/bufferModel.lua` →
  empty, so ours is byte-identical to theirs). Observable from
  `tests/input/input_widget_callbacks_spec.lua`, *"editor Alt+Enter, an unclaimed variant"*.
- **What changed.** Before the import the editor opened with the last block selected; at HEAD it
  opens with the first. Measured on the document `{ 'first line', 'second line', '' }` that three of
  our cases use: at `21eb7f53^` the selection was 3 and `up` walked to `'second line'`; at HEAD it is
  1, `up` moves nothing, and Enter loads `'first line'`. The HEAD half is no longer a probe — the
  Alt+Enter case asserts `{ 'first line' }` literally as of 2026-09-06.
- **What is owed is a record, not a change.** The behaviour is upstream's, deliberate, and taken
  faithfully; nothing here proposes to reverse it. The obligation is the merge plan's own rule, which
  this corpus applied correctly once in the same range and missed here: a behaviour change gets a
  record and a renaming does not. `T-NAV-ESCAPE` exists because that rule was followed; this entry
  exists because the import's re-pins classified the same class of change as a renaming — the commit
  that moved this case said it *"needed only its setup moved from Escape to Enter"*, and it needed
  more than that.
- **Where the record belongs is deliberately not decided here** (owner, 2026-09-06). The candidates
  are the editor internals doc, `CHANGELOG.md` if the release is judged to be shipping it to users,
  and the guide if anything there predicts the old selection. Choosing among them is the work; doing
  it now, from a session that is not fixing it, would be guessing.
- **Reachability:** every time the editor opens, which makes it broad and undramatic — nobody loses
  data and nothing misbehaves. The cost is to us, not to users, and it has already been paid once:
  navigation cases written before the import have setups that no longer navigate. Three still press
  an `up` that walks from the top of the document to the top of the document; one has been dropped
  with a comment, and the two in *"editor Escape falls through to the widget"* are harmless and
  left. A reader debugging any of them will assume the selection moved.
- **Found:** 2026-09-05 by session75's delivery review (its `F3`), while checking whether the
  import's five re-pins were renamings or behaviour changes. Four were what they claimed; this was
  the fifth. Registered as its own entry by owner ruling, 2026-09-06 — the review had proposed a
  clause on `T-NAV-ESCAPE`, and a documentation obligation that lives as a sub-clause of another
  entry's *"what changed"* is not findable by anyone looking for it.
- **Roadmap:** owner-ruled 2026-09-06. It is a documentation obligation with no
  mechanism to build, and it is release-scope because the release imports the change — so it belongs
  to the sprint that passes over the internals docs rather than to one that changes behaviour. The
  row inherits the open question above rather than closing it: which document takes the record is
  still the work, and that pass is where a writer has all three candidates open at once.

### T-NAV-ESCAPE — bare Escape in the editor's navigation mode now runs the widget's cancel (RESOLVED, 2026-09-09)

**PAID 2026-09-09, with no editor-side change**, exactly as the 2026-09-07 ruling
said it would be: the editor's widget seats no lifecycle flags, so the fall-through runs a cancel
that does nothing. **The two cases this entry named as the ones that invert did invert, and nothing
else went red** — navigation in `tests/input/input_widget_callbacks_spec.lua` now asserts the flow
is reached and destroys nothing, and editing in `tests/input/input_editor_keys_spec.lua` asserts
the open block survives, which is the breaking test for the data loss.

**The documentation line it was owed is written**: `../internals/user_input.md`,
under the cancel flow — the editor claims the key nowhere, the widget gets it and starts a cancel
that is deliberately empty. `../decisions/input.md`, `D-EDITOR-KEYS` statement 1 records the same
thing as the contract being honoured for the first time.


**RULED 2026-09-07 — THE QUESTION DISSOLVES, and it was already neutralised by a decision taken for
other reasons** (owner): *"we neutralized defect by planning to make editorial
widget non-destructive (no hide, no clear) on its own 'cancel'. therefore, the problem dissolves —
whether editor claims Escape for something else is its own business."*

**What this settles.** The entry was written as a product question — *should the editor claim bare
Escape?* — and the answer is that **it does not matter to us.** With `D-LIFECYCLE-FLAGS`, the
editor's widget seats no `clear_on_cancel` and no `hide_on_cancel`, so the fall-through runs a cancel
that **does nothing**. The key reaching the widget stops being a loss the moment the widget's cancel
is inert, and what the editor does with Escape becomes the editor's own business rather than a
contract we have to negotiate.

**This is not a new commitment.** The flags work already builds the four flags and already lists this
entry among what it closes; nothing is added to the release by this ruling. What changes is the
*reason* the entry closes — inert-by-default, not a claim negotiated with the editor — and that the
ruling **forecloses the other branch**: we do not ask the editor to claim the key, and we do not
re-litigate `D-EDIT-LIFECYCLE`'s consume-upstream sentence as if the fix depended on it.

**One documentation line is owed and is scheduled as part of the flags work** (owner: *"worth a line in the
documentation"*): *if the editor does not claim Escape, the widget gets it and runs its own cancel,
which is purposefully configured to do nothing.* It is not written here because the flags are
**decided and not implemented**, and the guide describes shipped behaviour.

- **Where:** `src/controller/editorController.lua`, the navigation-mode key handling, meeting
  `src/controller/userInputController.lua`'s `cancel_flow`. **Both modes are pinned as of
  2026-09-09, and the flags work inverts exactly these two cases:** navigation in
  `tests/input/input_widget_callbacks_spec.lua`, *"editor Escape falls through to the widget"* →
  *"is not claimed by the editor in navigation"* (whose sibling case pins the `Shift+Esc` half of
  the same seam), and **editing** in `tests/input/input_editor_keys_spec.lua`, *"clears the open
  block, losing the edit"*. Both carry a `FLIP:` comment naming `../decisions/input.md`,
  `D-LIFECYCLE-FLAGS`; a case going red anywhere else is a regression, not this fix landing.
- **What changed, and it is a behaviour change this branch did not choose.** Before the import,
  bare Escape in the editor meant *load the selected line into the input*, and the editor
  **consumed** it (`block_input()`), so the widget's `cancel_flow` never ran there. Upstream PR
  #45 moved the load onto **Enter and typing** (its spec 2.2) and gave the discard/leave to
  **Shift+Esc** (2.3). Bare Escape is now claimed by nothing in navigation, so it falls through
  to the widget and runs `before_cancel` → clear → `after_cancel`.
- **Why it is registered rather than absorbed.** Two reasons, and the second is the one that
  matters. First, the merge plan's own rule: a cascade beyond the four known conflicts is filed
  with a planned step rather than absorbed silently. Second, **the corpus asserts the opposite in
  prose**: `../decisions/input.md`'s `D-EDIT-LIFECYCLE` explains the design through *"the editor
  consumes Enter/Escape upstream through `block_input()`"*, which is now true of Enter and of
  Shift+Esc but **not** of bare Escape. A reader meeting that sentence will predict the wrong
  behaviour.
- **Why it may nevertheless be right.** It is `D-CHAIN-OF-3` behaving exactly as designed — a key
  no participant claims falls through to the next one — and what it produces is Escape clearing
  the editor's input line, which is what Escape does everywhere else in this API. **The question
  is not whether the mechanism is sound; it is whether the editor should claim the key.** That is
  a product question about someone else's subsystem, which is why it is not answered here.
- **Reachability: every Escape press in the editor, and the entry's own name under-scopes it.**
  In **navigation** it is harmless, as first recorded — the input line is empty, so the clear has
  nothing to clear. **In EDIT mode it is data loss, and that was never recorded**: `_normal_mode_keys`
  serves both modes and `discard()` requires Shift, so bare Escape is unclaimed in edit too, falls
  through, and `cancel_flow` empties **the block the user opened**. Probed 2026-09-06 — open a block
  with Enter, the widget holds `first line`; press bare Escape, the widget holds nothing and the mode
  is still `edit`. **This is the primary editing path, not a corner**, and it makes the entry
  release-blocking rather than latent. The slug is kept for citation stability
  — a renamed id dangles visibly where a renumbered one silently resolves to the wrong thing; **read it as *bare Escape in the editor*,
  both modes.**
- **The product owner's stated intent points the other way, and it was found rather than assumed**
  (2026-09-05, owner's prompt). It is **@dsent's** — the edge's author — Escape guidance, now
  carried as recommended UX in `../../input_api.md` (*"Setting the lifecycle flags"*), and it said
  two things that bear directly on this entry:
  - ***"Clearing on Escape is the P1 data-loss hazard"***. The merged behaviour here **is**
    clearing on Escape, in the one surface that guidance exempts.
  - ***"The always-shown console and editor widgets keep their own Escape."*** The editor's widget
    is `always_shown`, and what it has now is **not** its own Escape — it is the generic widget
    cancel, reached because nothing upstream claims the key in navigation.
  **And #45's own design agrees in shape:** it gave the discard to `Shift+Esc` and made it *ask
  when the block is changed*. Both authors are careful about destructive Escape; the fall-through
  is careful about nothing. **That is evidence for *the editor should claim the key*, and it is
  the strongest input available to the ruling** — but it is still a ruling, because a proposal is
  not ratified, and only a later row decides what the release absorbs.
- **Provenance: the merge.** Neither side has this behaviour alone — #45's cancel never runs on the
  editor route, and our branch's editor consumed the key. It exists only in the union, which is the
  merge-risk class the plan registered as `R11` and stated as *"they changed a line
  we moved"* — high impact, invisible to both the merge and the suite, because neither side is
  wrong alone.
- **AMENDED 2026-09-06 (session76): upstream had an explicit guard against exactly this, and our
  own Phase R replaced it with an expectation.** The first statement of this entry said *"#45 has no
  `cancel_flow`"*. That is imprecise in the way that matters. Upstream **does** cancel on Escape,
  and it **excludes the editor route by a conditional in the same function**:
  `git show f4cf338c:src/controller/userInputController.lua` — `keypressed` branches on
  `if love.state.app_state == 'editor' then … else … cancel() … end`, and the editor arm **omits
  `cancel()` deliberately**. Upstream `dev` has the identical shape (`af9a5782`, same file). **Our
  branch deleted that branch**: commit `affc9320` (2026-07-21), Phase R, *"the app_state un-fork,
  option E"* — its own message reads *"userInputController.lua: delete the
  `love.state.app_state == 'editor'` branch; keypressed runs one uniform path"* and, in the same
  commit, *"editorController.lua: consume Enter/Escape upstream via `block_input()`"*.
  **The guard was not removed; it was moved out of the widget and into the other controller** — and
  that controller belongs to a subsystem this branch does not own and upstream was actively
  reworking. The live comment states the new arrangement in terms
  (`src/controller/userInputController.lua`, the submit/cancel-flow block: *"Editor/console callers
  that must not run these consume the key upstream (editor) or set no callbacks (console no-op)"*).
  **So this is not only two designs meeting at an unowned seam.** A route exclusion that upstream
  expressed as a conditional, this branch re-expressed as a cross-controller expectation; #45 then
  changed that controller, the expectation stopped holding, and **nothing failed, because an
  expectation cannot fail** — which is why the behaviour arrived silently and was found by an
  unrelated spec. **It also means a third option exists** beside *ship it* and *the editor claims
  the key*: restore the exclusion on the widget side, where upstream kept it. Whether that is
  right is a design ruling — `D-CHAIN-OF-3` and option E both argue against a route test inside the
  widget — but it must be **on the table**, and it was not.
- **Found:** 2026-09-05, by a spec of ours failing during the import and being read rather than
  re-pinned on sight. The re-pin asserts the new behaviour in both directions — bare Escape
  cancels, Shift+Esc does not reach the widget — so whichever way the question is answered, the
  answer has a test that will move.
- **Roadmap:** the one documentation line still owed. That ruling
  **closed 2026-09-07**: the flags make the editor's widget inert on its own cancel,
  so whether the editor claims Escape is its own business.

### The class diagrams show a model field that no longer exists (RESOLVED, 2026-09-02)

- **Where:** `../mermaid/input.md`, `../mermaid/editor.md`, `../mermaid/classes.md` — the
  `InputModel` / `UserInputModel` class blocks.
- **Pre-existing, and kept as history.** The mermaid class diagrams are `aldum`'s — four added
  2024-07-29 and three (`eval.md`, `input.md`, `scratch.md`) on 2024-12-18 as *"unfinished docs"*,
  last meaningfully updated 2025-01-13 — and were stale a year before this feature began.
  `InputModel`, `InterpreterModel`, `InputController`, `InputView` and their peers did not exist at
  the PR base `3256aac` either, so the drift they carry is inherited, not caused here.
- **Resolution: marked historical, not corrected.** Owner's call: *"if it's not the
  live doc and never was, maybe we should not update it, just mark (historical)?"* `doc/mermaid/README.md`
  carries the reasoning and each of the seven files got a one-line historical banner; no diagram
  content was rewritten, because these files are the record of intent and a correction pass would
  have deleted it.
- **One line of the 32 class blocks was ours** — `editor.md`'s `oneshot` on the live
  `UserInputModel` — and its deletion, with the field-by-field audit that found it and the entry's
  half-wrong original premise, is the branch's own working process and is vacuumed.

### `set_text`'s list branch does not split embedded newlines (RESOLVED, 2026-09-01)

- **Resolution:** fixed. The `type(text) == 'table'` branch hands
  its sanitised list to `string.lines`, which is polymorphic over
  `string | string[]` and delegates a list to `string.split_array` — so each
  element splits and empty elements are preserved. `set_text("a\nb")`,
  `set_text({"a\nb"})` and `set_text({"a","b"})` now produce the same two lines
  and the same cursor. One call; the two branches converge on the function the
  string branch already used instead of stating the rule twice.
- **Never slugged, and correctly so.** A slug is the commitment to fix and is
  earned when an entry becomes `ACTIVE`; this one was ruled and fixed in the
  same session, so it went `BACKLOG` → `RETIRED` without passing through.
- **The rule behind it is the owner's** (2026-09-01) and is now ratified as
  **D-CONTENT-NORM**, `../decisions/input.md`. It is the same rule the UTF-8
  sanitisation on this path already served: **the cursor addresses content as
  `(line, column)`, so content that is not normalised makes that address
  ambiguous.** Invalid bytes leave a column's *length* undefined; a newline
  inside a line leaves its *position* undefined — the caret could sit past a
  line terminator. Neither normalisation is a convenience, and they are now
  symmetric across both spellings. Written up in
  `../internals/user_input.md`, *"Multiline input"*, and stated for a project
  author in `../../input_api.md`, *"Live changes"*.
- **The two branches are now one path preceded by a normalisation step** (owner,
  2026-09-01), which is D-CONTENT-NORM's structural half: per-spelling branches
  that each decide what to normalise are what let UTF-8 and newlines drift onto
  different rules in the first place. `normalized_lines` returns the lines,
  `set_text` stores them, and there is one place left where either could drift.
- **The defect it closed:** the two branches of one function disagreed about
  what a newline means. `set_text({"a\nb"})` yielded **one** line holding a raw
  newline, which the model counted as an ordinary character — three characters
  long, caret positions `1..4`.
- **What was observable, established at the weighing** — more than the entry
  first claimed. The content round-trips through `string.unlines`, so
  `on_text_entered` could not tell the two apart; but `after_submit` receives
  the line list itself (D-PAYLOAD-SPLIT's payload split), so the spellings handed a
  project `{"a","b"}` versus `{"a\nb"}`. The validator runs per line and would
  have measured the concatenation and named the wrong line. And the rendering —
  recorded as *"needs a display"* — was read out of the draw code instead: both
  paths reach `gfx.print`, which honours the newline, and they corrupt it
  **differently**. `ViewUtils.write_line` draws the tail one row down at `x = 0`
  over its neighbour while the model still believes it drew one row, so the
  cursor, the visible window and the scroll arithmetic all disagree with the
  screen; the highlighted path prints character by character at explicit
  coordinates, so the newline draws nothing and reads as a blank column. Not
  display-verified — read from the draw code, which is why it was fixed rather
  than left described.
- **Why it was still narrow:** no in-tree caller could reach it. The three
  **project-facing** ones (`maze/core_editor.lua`, `tixy/main.lua` twice) pass
  either a raw string or `string.lines(…)`, and `string.lines` never emits an
  element containing a newline. **The enumeration was incomplete as first
  written** (cold peer review, 2026-09-01): the model's `set_text` is also
  called from `editorController.lua:336` and `:602`, from
  `UserInputModel:history_back` and `:history_fwd` (history restore) and from
  `userInputController.lua:316` (`show`'s `cfg.text`). All five were checked and the conclusion survives — `pprint`
  returns `string.lines(src)`, and buffer lines and history entries are already
  split — but "all three" would have let a reader think they did not exist. Nor could a user: `add_text` splits, and the paste path pre-joins
  with `string.unlines` at the controller before the model sees it. A project
  had to hand-build such a list, and **nothing could read it back** — the
  `compy.input` surface had no content getter when this landed, so there was
  no set/get round-trip the normalisation could break. (`get_text` arrived
  2026-09-03 and answers the normalised content, so the round-trip that exists
  now agrees with what this fix established rather than contradicting it.)
- **Provenance: pre-existing.** At the PR base `3256aac` the table branch is
  `InputText(text)` — no split, no sanitise. This feature fixed the *string*
  half (`T-MULTILINE-STR`) and thereby made the two halves visibly disagree; it
  did not introduce the branch. Two refinements found at the weighing: the
  per-element sanitise pass **is** ours, so the branch carrying the split is
  code this feature wrote, and the asymmetry — UTF-8 on both spellings,
  newlines on one — was its own choice rather than an inheritance. Found by the
  cold peer review of the fix that exposed it.
- **Where:** `src/model/input/userInputModel.lua` (`set_text`),
  `tests/input/user_input_model_spec.lua` (*"embedded newlines"*, three cases),
  `tests/input/input_cursor_text_spec.lua` (the surface case, beside its string
  twin), `../../input_api.md`, `../internals/user_input.md`, `../../../CHANGELOG.md`.

### `set_text`'s two branches disagreed about the cursor, and the call was dead (RESOLVED, 2026-09-01)

- **Resolution:** fixed, in the same unit as the entry above and
  on the owner's direction — *"either discard or cursor movement should be
  deleted, and in either case both paths should be unified"*. The call is
  **deleted** and the two branches are now **one path preceded by a
  normalisation step** (`normalized_lines`). Ratified as **D-CONTENT-NORM**,
  `../decisions/input.md`, closing section.
- **Registered here rather than left in a session track** (owner, 2026-09-01):
  a finding parked in a track dies with the session, so it goes in the ledger
  even when it is fixed the same day.
- **The defect:** `UserInputModel:set_text`'s string branch called
  `_update_cursor(true)` when `keep_cursor` was falsy; the list branch never
  did. The call was **inert on this path**, so the asymmetry was invisible:
  `_update_cursor` sets `cursor.c` from the line at the *old* cursor index in
  the *new* text and `cursor.l` to `#t` — a column from one line and a line
  from another, incoherent by construction — and `set_text` then runs
  `init_visible`, which replaces the whole `VisibleContent`, and `jump_end`,
  which overwrites both cursor fields with coherent ones. Every effect,
  including the visible-range move `text_change`'s `_follow_cursor` makes from
  it, is discarded before the call returns to its caller.
- **It never worked.** The commit that introduced the call (`472c6bba`, the
  transitional UserInput triplet) already ended `set_text` with an
  unconditional `jump_end()`. There is no revision in which it had an effect,
  which is why the branch lacking it behaved identically and the disagreement
  survived unnoticed. Shape copied from `_set_text_line`, where the call **is**
  live, into a function that already seated the cursor.
- **Mutation-tested before deletion, not reasoned about only:** five cases
  chosen to expose it — shorter replacement with the caret parked past the new
  end, longer replacement, and a 20-line buffer collapsing to one line, each in
  both spellings — produce byte-identical cursor and visible-range snapshots
  with the call and without it, and the suite is green either way. The
  **behaviour** is now pinned by tests (*"both land at the end of shorter
  content"*); **the deletion is not, and cannot be** — an inert call is
  indistinguishable from its absence, so restoring it leaves the suite fully
  green. Reintroduction is not test-detectable, which is worth knowing before
  anyone reads those tests as a guard against it (cold peer review, 2026-09-01).
- **`_update_cursor` itself stays, and only the `set_text` call site was
  deleted. Corrected 2026-09-01, same day:** this entry first said
  `_set_text_line` and `clear_input` "both call it live", which is wrong about
  the first. `_set_text_line` guards the call with `if not keep_cursor`, and
  **all seven of its callers pass `true`** — so that call is unreachable, and
  `clear_input` is the only reachable one. The correction matters because the
  claim would tell a later reader that path is exercised when nothing exercises
  it. What the function owes beyond that is its own entry, below.
- **Provenance: pre-existing**, inherited from the transitional triplet and
  present at the PR base in the same shape.
- **Where:** `src/model/input/userInputModel.lua` (`set_text`,
  `normalized_lines`), `tests/input/user_input_model_spec.lua`
  (*"embedded newlines"*).

### T-MAZE-NEUTRALIZE — `maze` neutralises two hook sites by clearing a flag, not by the widget guard (NOT DEBT, 2026-08-31)

- **Resolution: `wontfix`, by owner ruling — and the entry's premise was wrong.**
  The row opened by weighing rather than by fixing, and the weighing found
  nothing to weigh. No code changed in `maze`.
- **`ctrl_pressed` is maze's control-mode slot, not a neutralisation idiom.**
  `controls.lua` defines the modes and each one assigns it — `keys()` sets
  `handle_key`, `plan()` sets `plan_key` with a matching `ctrl_update`. Clearing
  it says *no control mode is active*, which is a statement about the game.
- **The contrast the entry drew inverts.** It read `core_editor.lua` as the file
  doing it the other way; `arm_editor` there is itself `ctrl_pressed = nil`. And
  that file's `is_shown` call is a **show-vs-configure** branch — *is there a
  field to reconfigure?* — not a double-handling guard, which is a different
  shape from `turtle`'s whole-handler early return.
- **Double-handling is prevented on the paths that occur — but by level
  ordering, not by structure.** The weighing first claimed "by construction";
  the sprint's peer review falsified that and it is corrected here. The hook
  fires while the widget is shown, finds `SYSTEM_KEYS[k]` nil — that table is
  only ever populated by member name — and `ctrl_pressed` nil, so the keystroke
  reaches the widget alone. **But `jump_level` → `start_level` → `cur_controls()`
  re-arms `ctrl_pressed` and hides nothing** (`compy.input.hide()` appears only
  in the two menu exits), so a jump from an editor level to a `controls = keys`
  level would leave both live. **Reported in maze's own `ISSUES.md`, not fixed** —
  it is that repo's defect and that repo's readers need to find it, where this
  ledger is ephemeral to them.
- **The shape is the one the guide advises** (owner, 2026-08-31): read the
  hardware early and turn the result into a deterministic variable the rest of
  the logic runs on — `../../input_api.md`, *"Perform hardware polling before
  complex processing"*. The only thing to say against it is that the variable
  is named after the keyboard where its role is mode selection (`special_mode`
  would say it) — **semantics and taste, explicitly not fixed**, in another
  repo's working code.
- **Where:** nothing changed. The decision not to rename was weighed when the
  fix landed and is recorded with it.

### T-BALLOON-LABEL — balloons keeps a shadow copy of the widget's label, re-pushed every cycle (RESOLVED, 2026-08-31)

- **Resolution:** fixed, in the **balloons repo** (a separate
  repo with its own remote, which opens its own PR alongside the platform one).
  `ui_messages.hint` and `ui_draw_hint` are gone; `ui_set_hint` writes straight
  through to the widget, with a comment carrying the reason the indirection
  existed.
- **Why it could go:** the copy had **no second reader** — it was written and
  read only inside the `ui_set_hint` → `ui_draw_hint` pair, so collapsing them
  loses no state. It existed because in the legacy era the label died with each
  `input_text()` call; with label stickiness ratified the widget owns the label
  and a prompt persists until replaced.
- **Three fossils went with it:** the `-- NOTE: won't work if there was no real
  input` comment (it described the flush-dependent redraw), `terminal_write`'s
  never-read `flushed` parameter, and the second argument passed to
  `ui_set_hint`, which takes one. The unused `SPLASH_HINT_START` seed went too;
  the constant stays, because the splash screen reads it directly.
- **Not runtime-verified:** balloons has no suite and needs a display. Desk-
  checked and parses; the manual smoke pass is where it is exercised.
- **A second defect was found here, raised, and then fixed on the owner's
  ruling.** `ui_draw_status` read `ui_messages.results`, which nothing ever sets
  — `ui_status_finalize` writes `ui_messages.result`, singular. It was reported
  rather than filed (`../conventions/code.md`, *Don't over-fix* — report non-blocking debt), and the
  owner ruled: *fix it if it is clearly a typo, delete it if it is clearly dead
  code.* It is the second, so the branch was **deleted** in the balloons repo.
- **Why deleting was right and repairing was not.** The two names are a
  self-consistent *pair* — `ui_status_reset` cleared `results`, `ui_draw_status`
  read it — so "repair the typo to `result`" would have changed nothing during
  play (`ui_status_finalize` sets the result immediately before the state
  becomes finished, where the splash renders instead of the status bar) and
  would have been a **regression across games** (`result` is never cleared, so
  game two's status bar would show game one's stats). Ask what the repaired code
  would *do* before repairing.

### T-CURSOR-BYTES — the cursor clamp counts characters, not bytes (RESOLVED, 2026-08-31)

- **The shipped rule is pre-existing.** `UserInputModel:move_cursor`'s bound
  predates the branch (unchanged at `3256aac`), and the whole model already
  addressed the cursor in *characters* — `jump_end`, `jump_line_end`,
  `is_at_limit`, `_update_cursor`, `cursor_left`/`right`,
  `cursor_vertical_move`, the mouse-to-cursor translation and the view's pixel
  math all count characters. The clamp now agrees, counting with `string.ulen`;
  the bound only narrows (`ulen` ≤ `#`), so nothing that passed before is
  refused now.
- **Where:** `model/input/userInputModel.lua` (`move_cursor`),
  `../../input_api.md` (*"Live changes"* — which states the rule with a
  multi-byte example).
- **Mixed provenance.** The externally-reachable half was the branch's own —
  our `set_cursor_pos`/`_clamp_cursor_pos` wrappers (absent at base) copied the
  byte convention and made the latent gap reachable, and it was fixed. That
  introduced-and-paid half records our working process, not
  the product's history, so it is vacuumed.

### T-MULTILINE-STR — `set_text` silently ignores a multi-line *string* (RESOLVED, 2026-08-31)

- **Resolution:** fixed. The string branch of
  `UserInputModel:set_text` now splits with `string.lines` and hands every line
  to `InputText`, which is where the table branch already handed its list. A
  single-line string yields a one-element list, so that path is unchanged.
  **The table branch did not itself split** — fixing this half is what made the
  two visibly disagree, and that is the entry above,
  *"`set_text`'s list branch does not split embedded newlines"*.
- **The defect it closed:** `self.entered` was assigned only when the string
  held one line, so a string with a newline matched no branch, nothing was
  written, and the previous session's content survived into the new one — with
  no warn and no raise. Reachable from `show{text = …}` and the live
  `compy.input.set_text`. **Corrected 2026-08-31** by the sprint's peer review:
  the fix commit's message also named `configure{text = …}`, which in fact
  **raises** — `text` is in `SHOW_ONLY_KEYS` (`consoleController.lua`) — and
  named `apply_config`, which no longer exists; the path is `api_show` →
  `open_widget` → `reset_content`. Both are wrong in the commit message, which
  cannot be amended, so the correction lives here, where the PR description
  will read it.
- **It was PRE-EXISTING, not ours.** The `#string.lines(text) == 1` guard is at
  the PR base `3256aac` in the same shape. What this feature added is the
  documented shape (`../../input_api.md`, *"The input widget — showing it and
  changing it"*: "a string or list of line strings") and the project-facing
  surface that reaches it — which is why it was fixed here rather than left
  described.
- **Where:** `model/input/userInputModel.lua` (`set_text`),
  `tests/input/input_widget_control_spec.lua`,
  `tests/input/input_cursor_text_spec.lua`, `../../../CHANGELOG.md` (*"Fixed"*).

### `wrap` guards the `xpcall` arity hazard on the platform, not the capability (RESOLVED, 2026-08-28)

- **Resolution:** the branch is gone rather than re-guarded. `wrap` now
  closes the arguments over a nullary function and calls
  `xpcall(fn, on_error)`, which asks nothing of the runtime — so there is no
  platform test left to disagree with the capability. Was `T-XPCALL-GUARD`.
- **Where it was:** `src/controller/controller.lua`, `wrap` — the `_G.web`
  branch, whose `pcall` side was correct for the Web build and unreachable
  for `busted` on PUC Lua 5.1, which is not the Web build. There the route
  was entered with nil arguments: **107 failures**, all under
  `tests/input/`, on a suite green on LuaJIT.
- **Not introduced by this feature.** `master` carries the same guarded
  `xpcall`, reached through `error_wrapper`/`set_handlers`, so on PUC 5.1 an
  adopted `love.keypressed`/`textinput`/`keyreleased` and `love.update`'s
  `dt` already arrived nil. The feature inherited the defect, widened it to
  every shortcut, hook and the widget, and supplied the first tests that
  could see it. The fix is therefore cumulative against the last release,
  not a repair of this branch's own regression — which is how `CHANGELOG.md`
  states it.
- **Guarded by:** `input_route_lifecycle_spec.lua`, "the boundary carries
  arguments on any runtime" — two cases driving a real keystroke with the
  global `xpcall` swapped for PUC 5.1's arity.

### `wrap`'s error handler is called with the wrong arity, so project raises vanish (RESOLVED, 2026-08-03)

- **Resolution:** `wrap` binds CC in a closure used by both branches
  (`2554d2e3`), so a raise anywhere in project code now reaches
  `user_error_handler` and suspends the run. Three rows pin it — pointer,
  `love.update`, and a keyboard hook as the control that the other two are not
  asserting something impossible. Owner ruling: a certainly-wrong behaviour is
  not preserved on the grounds that changing it was never approved, even
  though it is pre-feature.
- **Where it was:** `src/controller/controller.lua`, `wrap` — the non-web
  branch was
  `return xpcall(f, user_error_handler, ...)`. `xpcall` invokes a message
  handler with exactly **one** argument (the error), but the signature is
  `user_error_handler(CC, msg)`. So `CC` binds to the error string, `msg` is
  nil, and `'user error: ' .. msg` raises *inside* the message handler, where
  `xpcall` swallows it. Nothing reaches `suspend_run`.
- **Measured effect** (probe run 2026-08-03, asserting the handler executed
  before the raise): a raise in a project's **pointer handler** or in its
  **`love.update`** runs the handler, then vanishes — no error window, no
  console line, `app_state` still `'running'`. A raise in a **keyboard hook**
  suspended correctly, because that path already bound CC in a closure
  (`xpcall(fn, function(m) user_error_handler(CC, m) end, ...)`) and got the
  arity right. That closure shape is now the one `wrap` (`controller.lua`)
  gives every path; there is no `chain_native` function today — the name this
  path then carried is gone.
- **`_G.web` is falsy on the desktop build, so the broken branch was the live
  one.** The web branch passed both arguments and never had the arity
  problem. Its own flaw — returning bare `r` where the other branch returned
  `xpcall`'s `ok, res...` tuple, so the `@return` annotation described only
  one of them — was fixed alongside the wrapper collapse (`f1dc6aee`).
- **Why the web branch exists at all, established 2026-08-03:** it is not a
  stylistic duplicate. `xpcall(f, h, ...)` forwarding arguments to `f` is a
  LuaJIT / Lua 5.2 extension; PUC Lua 5.1 takes exactly two arguments and
  drops the rest, so on that runtime every handler would be invoked with nil
  for all of its parameters. `pcall(f, ...)` forwards on both. Measured here:
  LuaJIT gives `1, 2`; 5.1 semantics give `nil, nil`. The branch is therefore
  **load-bearing and must not be collapsed away** — a warning to that effect
  now sits on it in code.
- **Reach at the time:** `wrap` had three call sites — `wrapped_native`
  (pointer handlers), the loader, and the project `update` wrapper — plus
  `CC:wrap_handler`, which took `wrap` as its error handler, for the compy
  click handlers. All of those except the loader and the update wrapper have
  since been replaced by `guarded`.
- **Pre-feature, verified:** `wrap` and `user_error_handler` are
  byte-identical at the PR base `3256aac`. The input API neither introduced
  nor worsened this; it only made the contrast visible, because the keyboard
  chain's own wrapper does it correctly.
- **Consequence for the docs:** "A raise from project top-level and from a
  handler surface differently" (below) describes the handler path as
  reaching the error window. That holds for keyboard hooks only.
- **Kept as a closed entry** because two things in it are still live
  knowledge: why the web branch exists (above), and the fact that this
  subsystem's error path had a defect no test could see for the length of the
  feature — the argument for the Web-coverage entry that opens this section.

### Future input unification (RESOLVED, 2026-08-03)

- **The shipped state, which is also the pre-existing one.** Every channel —
  keyboard, text, pointer, and the derived singleclick/doubleclick events —
  routes through one chain with one error boundary and one lifetime
  (`../decisions/input.md`, D-ONE-LIFETIME). A shared contract across channels
  was in fact the pre-existing state: at the PR base every event installed
  through one path and none was released before stop. The derived clicks folded
  into hooks — `compy.singleclick` is gone and `compy.input.hooks.singleclick`
  replaces it.
- **What genuinely remains unproven** and is recorded separately: pointer
  combos, and whether a shown widget should consume clicks within its bounds.
  See "Pointer delivery is an unstructured broadcast" below.

### `love.handlers.userinput` is dead code (RESOLVED, 2026-08-07)

Deleted, with the local `clear_user_input` that existed only to feed it. Both
`love.event.push('userinput')` sites were present at the PR base
(`3256aac:userInputModel.lua`) and were removed by this feature, leaving the
consumer installed — the same shape as `wrap_handler`. Kept as a resolved entry
because the pattern recurs: when a producer goes, grep for its consumer.

### Input-only / pointer-only projects stay live in `project_open` (RESOLVED, ruling a)

- **Where:** `consoleController.lua`'s `run_project`; and in `controller.lua`,
  `user_is_interactive`, the module-local `user_pointer` flag,
  `mark_pointer_liveness` (which sets it), `set_default_handlers` (which resets
  it) and `love.quit`. **Named, not cited by line, deliberately:** a function
  name moves once and greps out, a line number rots silently.
- **Pre-existing defect.** A non-blocking project (no `update`/`draw` hooked)
  always dropped to `'project_open'` with the project route unconditionally
  released. For a project whose entire UI was the input widget or a pointer
  handler, submit was dead — typing reached the widget but Enter never fired —
  and Ctrl+Esc quit the whole app instead of returning to the console. Verified
  byte-identical on `master` (pre-`0022004`) — not an input-API regression.
- **Resolution:** owner ruled (a) — an input-only / pointer-only project is
  "live" without hooking `update`/`draw`. New predicate
  `Controller.user_is_interactive()` returns
  `love.state.user_input ~= nil or user_pointer`, where the module-local
  `user_pointer` flag is set in `mark_pointer_liveness` when a project installs
  any pointer/click handler and reset in `set_default_handlers`. `run_project`
  releases the keyboard route only when `not user_is_interactive()`, and
  `love.quit` stops-to-console for `app_state == 'running'` OR (`'project_open'`
  AND `user_is_interactive()`). The chain's single lifetime is
  `../decisions/input.md`, D-ONE-LIFETIME.

### Pointer delivery is an unstructured broadcast, not a chain (RESOLVED, 2026-08-03)

- **Resolution:** pointer joined the existing chain rather than getting a
  mirror of it (`../decisions/input.md`, D-ONE-LIFETIME). The gateway's pointer
  entries no longer deliver to the widget themselves; they hand the event to
  the active route like every other channel, and the widget is the chain's
  terminal. A pointer hook consumes on a truthy return, so a shown widget
  *can* now be starved of a click aimed past it — the capability this entry
  asked about.
- **What made it cheap in the end:** the owner's ruling that the
  keyboard/pointer split was self-inflicted rather than inherited (D-ROUTE-LIFETIME,
  amended). The consume contract itself cost nothing: measured across
  `life`, `sapper`, `tixy`, `paint` and `pong`, no project pointer handler
  returns a value, and the return was discarded in any case. So this was never
  the "two symmetrically mirrored chains" it was estimated as — one chain
  already existed and pointer simply entered it.
- **Still open, deliberately:** whether a shown widget should consume clicks
  **within its bounds** automatically. Nothing does bounds checks today; the
  chain gives a project the means to decide, which is a different answer from
  the framework deciding for it.
- **Also still open:** a pointer *combo* vocabulary (a modifier-only shortcut
  such as `ctrl` plus a button). Pointer has no shortcuts tier and enters the
  walk at the hook tier; D-ONE-LIFETIME records the question as not-decided.

### `UserInputController:keypressed` forked on `love.state.app_state == 'editor'` (RESOLVED — the `app_state` fork was removed, 2026-07-21)

- **Where:** was `src/controller/userInputController.lua:keypressed`, an
  `if love.state.app_state == 'editor' then … else … end` branch.
- **Old state:** A reusable input widget read global app-mode to change its own
  behaviour — both the editing keymap (order + Ctrl+D `modify`) and whether its
  Enter/Escape submit/cancel ran. Flagged by the owner (2026-07-20) as an
  abstraction leak: the widget could not be reasoned about — or migrated onto the
  new API by the editor later — without knowing it was "the editor." See
  `doc/development/decisions/input.md` D-EDIT-LIFECYCLE.
- **Resolution:** The branch is deleted; `keypressed` runs one uniform path. The
  two real differences moved to honest homes: (1) `modify` (Ctrl+D) is a
  per-instance `allow_duplicate_line` constructor flag, set only by the editor's input,
  mirroring `disable_selection`; (2) the editor consumes Enter/Escape **upstream**
  (`block_input()` in `EditorController:_normal_mode_keys`' `submit()`/`load()`),
  so the widget's uniform `submit_flow`/`cancel_flow` never runs for the keys the
  editor owns. No instance reads global mode. Suite green
  (`tests/input/input_widget_callbacks_spec.lua`, the `the same lifecycle on every route` group).
- **Revisit:** `allow_duplicate_line` is a one-off flag; the widget owning its own
  **combo table** (Ctrl+D and the lifecycle keys as registered combos an editor or
  project extends) is the better end-state the owner named — deferred with the
  console/editor migration (D-ROUTE-OWNS), not this pass. The former inline question
  at `:724` is retired (its concern is resolved
  in shape; the combo-table refinement is what remains).

### An `update_prompt` endpoint was asked for and declined; `configure` already is one

- **Where:** `src/examples/balloons/terminal.lua` — an in-file remark asks the API to expose an
  *"update-prompt"* endpoint so a game can write its own welcome message when its mode switches.
- **Declined, 2026-08-11 (owner).** It is sugar over `compy.input.configure{ prompt = … }`, and a
  second path to a decorative change costs the surface's orthogonality, which is not ideal
  already. *At best it is a pattern to recommend, not a function to add.*
- **And the project already has it**, which is the part worth recording: `terminal_write(msg)` in
  that same file is one line over one `configure` call, exposed to the game as `write`. So the
  recommended shape is not hypothetical — it exists, in the example that asked for the endpoint.
- **The remark's other half — "three functions juggling each other" — is not the win it looks.**
  Two of the three are load-bearing: the handler slot is late-bound because `ui.lua` requires this
  file, and so activates the session, before `main.lua`'s router exists. Inlining the third
  (`deliver`, which joins submitted lines into the one string the game's handlers take) saves a
  function and costs the comment explaining why the join happens. Left alone deliberately.

### `userlove` does not convey its semantics (CLOSED — ruled to keep, 2026-08-03)

- **Ruling:** the name stays. Owner, 2026-08-03: *"I'd not rename userlove,
  its nice and makes no harm itself."* The rename was the last item of the
  deferred naming cluster; the rest of that cluster resolved by deletion
  rather than renaming (see the entries above).
- **What the reader needs instead, and now has in the code comment:**
  `userlove` is *a table indexed by love-event name holding the project's
  handlers*. Both callers pass one — `set_user_handlers` the sandboxed `love`
  table, `restore_user_handlers` the saved `Controller._userhandlers`. That
  second caller is why the once-proposed `project_love` was dropped: it would
  have been true at only one of the two entry points.
- **Kept as a closed entry rather than deleted** because the wrong candidate
  is the useful part of the record: anyone re-proposing `project_love` should
  find the reason it was refused.
- **Note (2026-08-03):** this entry used to also cover `forward_keypressed` /
  `forward_keyreleased` / `forward_textinput`. Those were **deleted, not
  renamed** — they implemented the console route's widget gate, which
  D-ROUTE-OWNS rules out ("widget visibility is state on the widget, never a
  routing condition"), and which was unreachable once the failed-run teardown
  was fixed. Its description here was also wrong on fact: it routed to the
  console route's active *widget*, not to "the currently-active keyboard
  route".

### The console's prompt is drawn under a project that never takes over `love.draw` (DISPUTABLE, ruled to keep 2026-08-07)

`ConsoleView:draw` paints the console's own input strip whenever the screen mode is not
`editor` (`src/view/consoleView.lua`, `drawConsole`). A project that replaces `love.draw`
never reaches that path — the gateway's draw wrapper calls the project's own draw instead
(`src/controller/controller.lua`, `set_love_update`). A project that draws **through the
console terminal** and defines no `love.draw` of its own does reach it, so the console's
prompt stays on screen for the whole run, inert: the input route belongs to the project, so
anything typed at that strip goes to the project, not to the prompt it appears to offer.

The sapper example, since removed from this repository, was the case in hand — it rendered the
minefield as terminal output and bound only the derived clicks, so the strip sat under the game
field for the entire session.
Surfaced by the owner's smoke test as *"any chance to not show inactive console input at the
bottom?"*.

**Ruled to keep as-is (owner, 2026-08-07):** the console's drawing logic is not to be
conditioned on what a project happens to draw, for the cosmetic benefit of one pen-and-paper
example. The gate would have to distinguish "a project owns the input route" from "the console
is interactive again" — `inspect` being the second — which puts project-lifecycle knowledge
into a view whose job is to paint the console.

**Cost of leaving it:** the strip reads as an available prompt while it is not one. **Cost of
fixing it:** a state test in the view, invisible to the suite — the input fixture stubs the
`view.view` module wholesale, so `ConsoleView:draw` is not exercised by any row, and the fix
would be verifiable only by a human smoke test. Revisit if a project owner asks.
