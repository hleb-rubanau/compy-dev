---
description: Cross-cutting technical debt outside the input subsystem
status: active
audience: developer
authored: llm
reviewed: none
---

# General

Debt not tied to one subsystem — load-order/aliasing assumptions and shared-utility
semantics.

Three sections below, in disposition order — not severity, not intent:
**ACTIVE** is debt still owed; **BACKLOG** is real, acknowledged debt
deliberately deferred; **RETIRED** is paid, or turned out not to be debt.
*(The #77 input-API release **shipped 2026-09-12**; the `T-PR-*` ACTIVE epics
below are its **post-release corrective tail — no longer pre-release gates**, see
the [ROADMAP](../wip/77-new-input-api/ROADMAP.md)'s top box and each epic's own note.)*

---

## ACTIVE

> **The three `T-PR-*` epics below are the release tail, and the release has SHIPPED**
> (owner, 2026-09-27; the release shipped 2026-09-12). They were scheduled as pre-release
> work — the corpus passes, the human review, the device and example integration — but the
> release **did not wait on them**, so they are **no longer gates**. They stay `ACTIVE`
> because the corrective work is still owed, not because they block anything, and they name
> the **post-release corrective tail**:
> - `T-PR-CORPUS` — the live corrective-docs pass (ROADMAP Stage A), which ships as its own
>   follow-up docs PR;
> - `T-PR-REVIEW` — the human review the owner runs **after** that docs work (owner,
>   2026-09-27), a quality follow-up rather than a gate;
> - `T-PR-DEVICE-EX` — **no longer a gate**: the shipped surface **runs on real devices with
>   no complaints reported** (owner, 2026-09-27), so the device sign-off is satisfied in the
>   field; what remains under it is the external example repos' own PRs (`PREX`) and the
>   post-release upstream reconciliation.
>
> Each epic **names its constituent work under it** rather than spawning a row apiece; where a
> piece already has its own `ACTIVE` slug the epic **references it and the original stands**
> (owner ruling, 2026-09-09). The roadmap work-ids named inside are provenance — a fact about
> what was scheduled — not pointers to a working-tree file.

### T-PR-CORPUS — the shipped prose/code corpus is not finalized: readability, proof-reading and ledger hygiene are unpaid

- **Scheduling and status live in the plan, not here (owner ruling 2026-09-15).** The
  authority for *what runs, in what order, and whether it is done* is **Stage A of the
  Release-finishing plan** (`../wip/77-new-input-api/ROADMAP.md`); this entry records the
  cost and the reasoning. Each piece below — including the comment-verbosity compaction and `T-OVER-64` —
  has a plan row, and this slug **retires when its Stage-A rows
  complete**. The pieces below are the *why*, ordered to match the plan.
- **The pipeline is corrections → compaction → review** (owner ruling 2026-09-14,
  session100): the prose is made *correct* first, *compacted* second, and *read* last,
  so no pass reads or shortens text a later pass will change. The pieces below are
  listed in that order.
- **What is owed, by piece:**
  - **Name-accuracy and citation corrections** — **DONE session101.**
    Five corrections landed: `DEFAULT_CALLBACKS` → `default_callbacks()`
    (`../internals/user_input.md`; the function is at `userInputController.lua:18`),
    `SearchModel` → `Search` (`tests.md`, `overview.md`; the class is `Search`),
    `reset_before_exit`/`chain_native` restated as absent from `src/` today
    (`input.md`; the crash-path re-seed and `wrap` are the live mechanisms), and
    `T-CONSOLE-INPUT-UNUSABLE` restated to carry the fact rather than cite `wip/`
    (`ledgers.md §8`). Ran **first**, before the compaction sweep and the two review
    passes (owner ruling 2026-09-14), because a name corrected after review is one the
    reviewer already read wrong. The sprint-id control sweep stays the backstop.
  - **The documentation compaction sweep** — one deliberate pass over the
    stabilised prose corpus, cutting hard on comments/changelog/guides
    and carefully on the ledgers, which have no backend. Runs
    **after the corrections pass and before the review passes.**
  - **The readability review, then the proof-read** — in that order: readability
    restructures the text a proof-read would
    otherwise check twice.
  - **The `agents/` lift into the corpus** — it writes prose in, so
    it runs first of the closing passes.
  - **The ephemeral- and retired-id citation sweep** and the
    **remaining vocabulary/process work** — nothing left in either
    changes what a device pass can observe, which is why they trail the surface.
    **The citation sweep is DONE session98:** the closed-arc sweep (subjects absent at base and
    today, yet still narrated) found the persistent corpus and platform comments
    essentially clean — the earlier passes had done the work. One instance was
    vacuumed (`D-IGNORE-REPEAT`'s withdrawn-wrapper narration, its lesson promoted
    into the live prose first) and this sweep re-homed the one retired-id orphan
    (`T-DEC-NUMBERED`, which had lost its persistent home). The vocabulary/process work remains.
  - **The API-surface terminology normalization** — `simple`/`precise` →
    `basic`/`advanced` for the two named input surfaces (owner ruling
    2026-09-12, recorded at `../decisions/input.md`, `D-SIMPLE-SURFACE`
    statement 1, which supersedes the 2026-09-07 `simple`/`precise` ruling).
    **DONE this session** (session94): prose, comments and user-facing strings
    across the persistent corpus, `src/` and `tests/`; **stable ids/identifiers
    kept on purpose** (`D-SIMPLE-SURFACE`,
    `build_simple_surface`, `input_simple_surface_spec.lua`). Ships in this
    corpus-finishing PR, separate from the serial hotfix PR.
  - **The sprint-id control sweep** — a control step run late, with
    the normal expectation of 0–2 mechanical leftovers; it is the paying pass for
    **`T-EPHEMERAL-IDS`** (persistent ledgers citing sprint ids that only resolve
    inside the working tree). See that entry; it stands.
  - **The decisions ledger's interim-past vacuum** — the paying work
    for **`T-ARGUES-INTERIM`** (DONE session97; the goal entry was itself
    introduced-and-paid and was vacuumed to the archive with the prose it
    commissioned). No live entry remains.
  - **The debt register's never-shipped-outside-the-branch vacuum**
    — the paying work for **`T-NEVER-SHIPPED`** (RETIRED; the vacuum ran in
    sessions 95–96). See that entry.
  - **The comment-verbosity compaction over `src/`/`tests/`** (owner
    ruling 2026-09-14, session100) — the one deliberate pass over stabilised
    **comments** that the platform suite never got. The documentation compaction sweep
    is the docs-prose version
    of this pass; comments were scheduled for the same treatment as a *method* —
    compaction is its own substep, taken once, over stabilised material, not done as
    you go — and executed platform-wide **only
    in an example repo** — `P-18-10` took `keyboard`'s `input.lua` from 177 to 101
    comment lines without losing an argument. The platform `src/`/`tests/` corpus was
    left to the marker sweep and `T-OVER-64` alone, **neither of which touches
    verbosity**, so this is a real mirror of the gap that created the documentation
    compaction sweep for docs
    (2026-09-01). Same contour rule as the docs pass and an earlier pass on this branch: compact only the
    comment lines **this branch brought in** (`git blame --line-porcelain`), never
    vendored `src/lib/`. It runs **after the docs corpus work and before `T-OVER-64`'s
    64-column reflow**, so the reflow sees final comment text.
    - **A cold sub-agent review of the before/after comment diff**
      (owner ruling 2026-09-14) closes the pass: a Sonnet worker reads the comment-only
      diff (before vs after) and confirms **nothing substantial was lost while intent
      was preserved** — the one risk a verbosity cut carries. Standing hygiene applies
      (explicit `model`, prompt + output on disk, **no nested spawns**).
  - **The 64-column comment limit** remainder — **`T-OVER-64`**, the 64-column
    line limit, a hard rule that must not reach the PR; the comment gate before the
    slice cut carries the length check. See that entry; it stands. **The comment
    compaction runs before this**, so the reflow lands on the compacted comment text.
- **The trade-off being recorded:** the PR ships prose that has had a
  stabilisation-era cleanup but not the single final compaction, and ledgers that
  still carry interim archaeology and branch-only tombstones. This is a
  legibility debt, not a correctness one — nothing here changes behaviour — and
  it is real *input* debt for every later agent pass, because an uneven corpus is
  wrong input to inference, not merely unclear prose (the argument that moved
  the terminology-and-marker pass ahead of the merge).
- **Why it is `ACTIVE`, not `BACKLOG`:** `T-OVER-64` alone forbids `BACKLOG` — a
  hard rule that must not reach the shipping slice — and the corpus a stakeholder
  reads is finalised in the **corrective-docs follow-up PR** (post-release), not
  left as acknowledged-and-deferred debt.
- **Provenance: ours** (the passes are our own upkeep; `T-OVER-64`'s six lines
  are partly the branch's rename and partly one pre-existing offender).
- **Revisit:** in the post-release corrective-docs pass — **the corrections pass first**,
  then the compaction pass, then the `agents/` lift, the control sweep, and the
  two-pass docs review; **the comment compaction and its cold review run
  after the docs corpus work and before `T-OVER-64`'s reflow**, with the ledger
  vacuums and the citation sweep and vocabulary work folded into the same window.
  The referenced slugs retire when their piece is paid.

### T-PR-REVIEW — the PR has had no human code review, and no cold read of the whole assembled change

- **Scheduling and status live in the plan (owner ruling 2026-09-15):** the
  **Post-release follow-ups** section of the Release-finishing plan
  (`../wip/77-new-input-api/ROADMAP.md`) — the whole-PR cold read and the human
  review. This entry records the cost; the slug retires when the review runs.
- **What is owed, by piece:**
  - **A human code review** of the submitted PR — the owner runs it **after** the
    corrective-docs pass (owner, 2026-09-27); it has not happened yet.
  - **The cold read of the *whole* PR**: code changes, tests and prose
    together — an optional quality follow-up, run after the corrective-docs slice
    is cut.
- **The trade-off being recorded:** the change shipped before any reader
  other than its authors — human or cold-agent — had read it end to end. Any
  defects either surfaces are fixed as **post-release corrections**; a review
  that finds nothing is still owed until it has run.
- **Why it stays `ACTIVE`:** the human review is still owed and live work, not
  acknowledged-and-deferred debt — but it is a **quality follow-up, not a gate**
  the (already-shipped) release waited on.
- **Provenance:** operational need (a claim is verified before it ships; an
  operational-need entry is exempt from citing a backing decision).
- **Revisit:** after the corrective-docs pass — the human review on the
  reviewer's schedule, and the cold read of the whole change. Both feed any
  fixes back as post-release corrections.

### T-PR-DEVICE-EX — the shipped surface has never had end-to-end testing on the device, and the external examples are integrated against an earlier API, not re-fitted to it

- **Scheduling and status live in the plan (owner ruling 2026-09-15):** the
  **Post-release follow-ups** section of the Release-finishing plan
  (`../wip/77-new-input-api/ROADMAP.md`) — the example re-fit, the per-repo example
  PRs, and the post-release upstream reconciliation. **The device sign-off is no
  longer part of it:** the shipped surface **runs on real devices with no complaints
  reported** (owner, 2026-09-27), so device validation is satisfied in the field.
  This entry records the cost; the slug retires when the example PRs (`PREX`) are up.
- **What is owed, by piece:**
  - **Device validation on real hardware — no longer a gate** (owner, 2026-09-27):
    the release shipped and the surface **runs on devices without complaint**, so
    the sign-off the release was once said to owe is satisfied by field use. A
    thorough end-to-end device pass remains **available as optional confidence** —
    the prior device runs were against interim versions of the surface that have
    since moved (the #45 import, the lifecycle flags, the non-destructive
    activation, the single payload, the positional `compy.ask`, the whole basic
    surface) — but it is a follow-up, not owed work.
  - **Re-fitting the already-integrated examples to the shipped API** — this is
    **not integration from scratch** (owner, 2026-09-09): *some* external examples
    were integrated onto the new input API in an earlier pass, but against a
    version of the surface that has since moved (positional `compy.ask`, the
    lifecycle flags, the non-destructive activation, the single payload, the
    basic surface). Each such example needs re-fitting to the surface as it now
    stands, with adjustments that **may be trivial or may be substantial — which
    is not yet known per example**. What remains to be integrated fresh, if any,
    is the tail of the same work.
  - **`PREX` — each external example repository opens its own PR** against its own
    remote (`keyboard`, `maze`, `balloons`, and the scope **may be wider**), read
    against the platform build it targets, so it runs **after the platform PR**.
    This includes **`T-DRIFT-KEYBOARD`** (the `keyboard` example one commit behind
    its renamed upstream), which retires when that repository's PR is opened. See
    that entry; it stands.
  - **The standing design-level item** *"Examples are not onboarded onto the new
    input API"* (`BACKLOG`, `input.md`) is the same work seen from the API side;
    the re-fit is where it is exercised end to end.
- **The named risk (owner, 2026-09-09):** device testing and the example re-fit
  **may surface defects, and they may land on either side** — a platform-side fix
  to this branch, or an example-side fix in the example's own repository. Neither
  is scheduled work today; both are expected outcomes of running the passes, and
  the fixes ship in whichever tree owns them. Because the device has never run
  *this* surface end to end, the yield here is genuinely unknown — it is not the
  low-yield confirmation a re-smoke of unchanged behaviour would be.
- **Upstream reconciliation remainder:** the platform upstream reconciliation
  remainder is named here so it is not lost — post-release work (`MERGE-01-06`),
  like the rest of this epic now.
- **The trade-off being recorded:** the surface shipped validated by the test
  suite (`busted`, 1174/0/0/9) and has **since run on real devices without
  complaint**, but no *thorough* end-to-end device pass over the surface in the
  form it now takes is on record — the device runs on record predate the surface's
  significant moves. The example projects that demonstrate the API sit on an
  earlier version of it, not yet re-fitted to the shipped surface nor re-validated
  against it.
- **Why it stays `ACTIVE`:** what keeps it live is the **example re-fit and the
  external example PRs** (`PREX`) — genuine outstanding work in their own repos —
  not a device gate; the device sign-off is satisfied in the field, so this is a
  **post-release follow-up, not a gate**.
- **Provenance:** operational need (the example PRs are obvious follow-up
  preparation — exempt from citing a decision).
- **Revisit:** the example PRs after the platform PR; the optional device pass at
  will. Defects surfaced by either are fixed as post-release corrections,
  wherever they land.

### T-DRIFT-KEYBOARD — the keyboard example is one commit behind its upstream, and its upstream was renamed

- **Where:** the `keyboard` example repository. Upstream is one commit ahead (`96d6629`,
  2026-08-20): it adds `.compy/build` (32 lines, no source file touched), following the packaging
  convention `maze` set — one source tree emitting two shipped projects, `keyboard/` and `k/`, so a
  beginner reaches the typing game without typing eight letters.
- **State:** merges clean (verified). **Blast radius: packaging only** — nothing it adds is read by
  this feature, and nothing this feature changed is read by it.
- **What it costs:** one merge, no decisions. Checked rather than assumed (2026-09-03), because
  "merges clean" and "costs nothing" are different claims: the build script copies `*.lua` and
  `README.md` from a flat tree, our branch is 37 commits ahead there, and its file set is identical
  to upstream's apart from the script — every commit changed an existing file, none added one. So
  the script emits our tree correctly.
- **A caution about the sibling repo:** `maze` set this convention first, but its build script lists
  its sources by name rather than globbing, so a file added but not listed is silently absent from
  the shipped project. Our `maze` work adds no file (its tree differs from upstream only by a
  repo-local `ISSUES.md`, correctly not emitted), so nothing is dropped today. The hazard is the
  next person's, not this feature's.
- **A second finding:** the upstream repo was renamed (`keyboard` → `compy.keyboard`). The old URL
  still redirects, so nothing is broken yet. Worth correcting when that repo's PR is opened.
- **Provenance: not ours.**
- **Revisit:** before that repository's PR, where this entry retires (owner, 2026-09-04). The commit
  is packaging this feature neither reads nor changes, so taking it — with the rename above — is
  preparation for that repo's PR, not release work; it is paid after the platform PR.

### T-OVER-64 — the feature's own lines over the 64-column limit, deferred to a content-preserving reflow at the end

> **Status (2026-09-27): the reflow is DONE (session110** — `969df43d`; ROADMAP
> Stage A). The feature's own over-64 lines are reflowed and the slice is clean.
> This entry stays here only because **`PR-01-01`'s comment gate cites it as a
> predecessor obligation**; it retires when that corrective-docs slice is cut. The
> body below is the record of the deferral, kept until then.

- **Correction, 2026-09-12 (session94):** this entry read *"six comment lines"*.
  That counted only the collateral of the `D-NO-FW-TIER` → `D-EDIT-LIFECYCLE`
  rename (a longer id pushed six lines over). The **base** feature-brought debt —
  lines this feature authored over the limit from the start — was never counted.
  The real figure is **~52 lines**, and the limit is **all-lines**
  (64 characters, every line — not comments only), so test **code** counts too:
  `it()` / `describe()` strings and long assertions, not only comments.
- **Where — re-derive, and count CHARACTERS not bytes.** An `awk 'length>64'`
  over-reports badly, because the comments use em-dashes (3 bytes each) that a
  byte count reads as over-length while the display is not. Count char-accurately
  over the **feature's own files only** — not pre-existing platform offenders
  (there are hundreds: `jni.lua`, `debug.lua`, `view.lua`, `editor_spec.lua` —
  all out of scope, the decision is *do not fix what the feature did not bring*),
  and not the #51 serial import:

      perl -CSD -ne 'print "$ARGV:$.\n" if length>64' \
        $(git ls-files 'tests/input/*.lua' 'tests/helpers/input_fixture.lua' \
          'src/controller/userInputController.lua' \
          'src/controller/projectInputController.lua' \
          'src/model/input/*.lua' 'src/view/input/*.lua')

  As of 2026-09-12 that is **~51 lines** across a dozen files (heaviest:
  `input_events_spec.lua` 14, `input_widget_callbacks_spec.lua` 13,
  `input_shortcuts_click_spec.lua` 5, `input_fixture.lua` 5, `userInputModel.lua`
  2), **plus one** in `consoleController.lua` (`build_widget_api`'s signature).
  **The comment-gate command still uses `awk 'length>64'`
  (bytes) and will over-report — flagged for the gate to switch to a char count.**
- **State: an accepted deviation, not an oversight** (owner, 2026-09-05).
  Renaming `D-NO-FW-TIER` to `D-EDIT-LIFECYCLE` on 2026-09-05 added four
  characters to every comment carrying the id, and six lines crossed. The
  owner declined a reflow at rename time: *"no need to reflow for length —
  better do reflowing once, later at prose compaction step."* One of the six
  (`:805`) was **already** over the limit before the rename and is not this
  branch's doing.
- **Why deferring is the cheaper order:** a reflow re-wraps a comment block,
  and comment compaction is scheduled as its own
  substep near the end, taken **once**, over stabilised material. Reflowing
  now means reflowing the same blocks twice, and the second pass would be the
  one that has to be right.
- **Revisit:** the comment sweep that precedes slice regeneration. It is
  already the pass that opens these files, and the limit is checkable
  mechanically once it does — **that gate now carries the length check as well
  as the marker check**, and the slice cut cites this slug as a predecessor
  obligation, so the pass meets the entry instead of chancing on it.
  **This must not reach the PR** — the limit is a hard rule,
  and what is deferred here is when it is paid, never
  whether. **ACTIVE, not BACKLOG** (corrected 2026-09-05): BACKLOG means
  *deferred past this release*, which contradicts the sentence above it.
- **How it is paid (owner, 2026-09-12).** The reflow runs **at the end**, and as
  **its own isolated commits, separate from any compaction pass** — because a
  reflow **guarantees the content does not change** (only wrapping moves),
  whereas compaction rewords. A reviewer must be able to glance at a reflow
  commit and see nothing but re-wrapping. So: keep the scope **sane and
  glance-able**, one file or a few per commit, in the corpus-finishing PR;
  **touch only lines the feature brought in** — never a pre-existing offender and
  never a file the feature did not touch. It stays deferred until then.

## BACKLOG

### The branch is 15 commits behind the platform's experimental line, beyond the editor rework — 11 changes

- **Where:** the platform repo's edge line (`5a52cba2`, 2026-09-03), 71 commits ahead of the line
  this branch develops against. 52 of those are the editor rework (`T-DRIFT-PR45`), and 15 are this
  entry — not 16, because the filesystem-durability API is already an ancestor of our head.
  Re-derive with `git rev-list --count --no-merges HEAD..<edge> ^<rework>`, subtracting both.
- **By content it is 11, not 15 — counting by hash overstated it.** The two lines cherry-pick
  between each other, so the same change exists on both with different hashes; `git cherry HEAD
  <edge>` compares patch-ids instead. Four of the fifteen are already ours (the editor checkpoint's
  filesystem info, the extended-palette termcolor fix, the terminal repaint gate, black's own bright
  slot), and three more are alternate versions of colour work we already carry — which is why the
  colours example collides as an add/add rather than applying.
- **What is in the 15:** the 64-slot colour palette and its terminal-colour fixes, a colours
  example, the editor checkpoint's filesystem info, packaging changes (zip instead of 7-zip, release
  signing), a Lua 5.1 test-runner launcher, the Android exit path, a terminal repaint gate, the
  per-character input render-cost fix (its own open upstream PR), and a storage-fallback label at the
  prompt.
- **Analysed by essence, not only by conflict** (2026-09-03) — "does it merge" and "does it still do
  what it did" are different questions. Three findings, most important first:
  - **The Android exit path is silently lossy against our tree.** It reroutes every full exit through
    a request that `love.quit` consumes by returning to the launcher first — including the
    Ctrl+Escape handler, which this branch moved into the privileged reservation table. A project's
    typed `quit()` takes the change cleanly, but the reservation keeps calling `love.event.quit()`
    directly and never raises the request. So the defect is in the line that does *not* conflict:
    resolving the visible hunk correctly still ships it, and it fails only on a device, where no
    headless suite sees it. One line fixes it — the reservation calls the request instead.
  - **The prompt label widens from a string to a string or `{ text, tone }` table**, and this
    feature's public `prompt` key writes exactly that field. Verified: with the label passed
    correctly, the widened form works through our constructor. So the question is whether the guide
    admits it, refuses it, or stays silent — a surface decision, not a break.
  - **Two draw-path changes cannot be cleared here at all** — the per-character render-cost fix
    (which deletes lines from the function this branch also edited) and the terminal's dirty-flag
    repaint gate. Their failure mode is a stale or mis-drawn frame, invisible in this display-less
    container. They belong on the device pass, and are named rather than cleared.
  - Everything else is additive or outside this subsystem. The palette is new slots plus two things
    to check once: black gains its own bright slot (changing an existing symbolic combination), and
    an out-of-range index now raises where it was tolerated.
- **What it costs:** measured by building the whole stack and running it — branch, editor rework,
  then this line: 1108 passing / 22 failing, and the 22 are the same ones the editor rework already
  owed. This line adds no new failure. Its two casualties were positional call sites assuming the
  pre-rework constructor shape, fixed in place. What needs hands: the console model, an add/add on
  the colours example (same file by two routes, 245 vs 247 lines), `.gitignore`, the one-line exit
  routing, and one surface decision.
- **Provenance: not ours.**
- **Deferred by decision, not neglect** (2026-09-03): this release shipped on the editor rework; the
  rest of the edge follows afterwards.

### `@field` annotations disagree with their own constructors in at least three files

- **Where:** `src/model/editor/bufferModel.lua:125` — `@field replace_selected_text function`
  names a method that was never implemented (the real one is `replace_content`, called from
  `editorController.lua`). `src/view/editor/bufferView.lua:31` — `@field buffers
  Dequeue<BufferModel>` is never assigned or read; the runtime field is singular `self.buffer`.
  `src/view/editor/visibleStructuredContent.lua:19` — `@field size_max integer` is declared on
  the class but only ever exists nested at `self.opts.size_max`.
- **Why it is one entry and not three:** three independent files, the same defect shape, found by
  one pass that was looking for something else. That is the signature of a class rather than a
  set of typos, and the likely mechanism is visible in the third instance — a constructor
  refactored to take an options table without the annotations following it.
- **Why it matters more than a stale diagram:** an `@field` is read by the language server, so a
  wrong one is offered as a completion and type-checked against. It misleads a reader, an editor
  and an agent, and unlike a diagram it sits in the file being changed.
- **Provenance: NOT ours, and identical at the PR base `3256aac`** — all three annotations are
  byte-for-byte the same there. This is the platform author's code and the entry is recorded, not
  claimed: the standing practice is to measure against the base first and not to refactor another
  author's subsystem on the way past.
- **Also seen, same pass:** `love.state.app_state` takes the value `'snapshot'`
  (`consoleController.lua`), which is real, current, pre-existing, and absent from the `AppState`
  alias in `types.lua` **and** from both FSM diagrams. Same category — a declaration that does
  not match the code.
- **Found:** 2026-09-02, by the `doc/mermaid/` audit commissioned separately, out of that
  audit's scope and seen in passing. The audit was looking at diagrams; these are in the source it
  checked them against.
- **Not slugged** — pre-existing, not this release's to pay, and an upstream conversation rather
  than a branch task.

### Line citations across the persistent corpus are unverified, and a fifth of the checkable ones do not resolve

- **Where:** every `doc/` file outside `wip/` that cites source by line —
  `technical_debt/input.md` (24), `internals/user_input.md` (19),
  `internals/event_dispatch_layers.md` (17), `internals/project_sandbox_env.md` (6),
  `internals/editor.md` (4), `tests.md` (3), this file (2), `internals/console.md` (2),
  `internals/examples/repl.md` (1), `drawing_system.md` (1). 77 distinct `file.lua:N` references.
- **State, measured 2026-09-01:** 62 resolve to a basename unique under `src/`; the other 15 name
  files that exist in several repos (`main.lua`, `input.lua`, …) and were not checked at all.
  **Of the 62, fourteen — 23% — land on a blank line or a bare `end`.** That is a floor, not the
  count: a drifted citation can also land on plausible code, which is how
  `userInputModel.lua:487` passed as a history-restore `set_text` while pointing at
  `self:clear_input()`.
- **Why it matters:** it is the same hazard as citing a decision by a number that later shifts —
  the reason the decisions ledger moved to names with a crosswalk (`../decisions/input.md`). A
  citation by a coordinate that moves
  **resolves to the wrong thing instead of dangling**, so it reads as authoritative and greps
  clean — the same argument that keeps ids in code as names rather than numbers, and comment
  citations as section names rather than paragraph counts. Line numbers are the
  same hazard with no mitigation at all: nothing in the workspace can tell you one has drifted.
- **How it happens is ordinary, not careless:** the six `userInputModel.lua` line citations this
  branch corrected were written in the very commit that shifted them, by a session that had verified
  each one before its own unrelated edit moved the file. No sweep catches that; only not citing lines
  does.
- **A worked instance of the worse mode, found 2026-09-02:**
  `internals/event_dispatch_layers.md`'s Layer-2 section cites `controller.lua` by line about a
  dozen times and **every one checked was wrong by roughly 110 lines** — `:854-860`, offered as
  `set_default_handlers`'s internals, lands in the profiler helpers; `:234-297` and `:974-982` name
  the wrong functions; `main.lua:389-390` and `consoleController.lua:1033`/`:1130` land in
  unrelated code. None of them dangles. All of them read as authoritative, which is this entry's
  point made in one document. The three that carried a claim being corrected were replaced with
  symbol names; the rest were left, because they are this entry's work and not that row's.
- **The fix is the one the corpus keeps re-deriving:** cite the **function or section name**.
  Where a line is genuinely the point, cite the name and quote the line's text so a reader can
  grep it. Sizing is real work — 77 references, and the 15 example-repo ones need the repo
  identified before they can even be checked.
- **Provenance: mixed and mostly ours.** The corpus is `#77`'s own creation (at
  `wip77/20260826/mergebase`, `doc/development/` holds five entries), but the practice of citing
  by line predates the feature and is not confined to it.
- **Not slugged** — no commitment to fix; that is an owner call. If taken it is a
  `FIX` row, and it belongs beside the id-citation sweep, which runs late for the same reason: a citation
  sweep run while the tree still moves is run twice.

### The conventions the examples demonstrate carry no test coverage

- **Where:** `src/examples/` and the nested example repos. No example anywhere
  in this codebase has spec coverage; the suite exercises the framework and
  never an example.
- **State:** the gap has teeth because the examples are not only samples — the
  guide points at them and projects copy them, so a convention that rots in an
  example rots in every project derived from it. `turtle` is the worked
  case: it double-handled its own keys for months while the suite stayed
  green, and its fix is likewise pinned by nothing. **End-to-end testing of
  examples is overkill and is not what is owed here** (owner, 2026-08-30).
  What may be worth pinning is the narrow set of conventions the examples
  *share* and the documentation *relies on* — the `is_shown` guard on a native
  handler, the one-shot echo guard on a trigger key, `after_submit` hiding the
  widget once per command — each of which is a documented promise today with no
  test behind it at the point a project author would copy it.
- **Why it stands:** deliberately deferred past this feature's (shipped) release
  (owner, 2026-08-30). Building it means a test genre this codebase does not have —
  driving an example's own `love.*` handlers through the framework's dispatch
  — and inventing that genre inside a defect row is how a defect row becomes a
  project. The framework side of each convention *is* already covered; what is
  missing is the example side.
- **Revisit:** when an example convention next breaks silently, or when the
  examples are next reworked as a set. **No roadmap row points here on
  purpose** — it is out of release scope, and a row would claim otherwise.

### The test suite passes only in declaration order

- **Where:** the whole suite, not one file. `busted tests` is green; `busted tests --shuffle`
  fails 29–55 rows per run, varying with the shuffle. Concentrated in `input model spec`
  (~23 rows), `Editor #editor` (~10) and a few `Dequeue` rows, but the set is not stable
  between runs.
- **State:** pre-dates any current feature work. Checked against the PR base `3256aac`,
  before the input-API branch existed: **674/0/0/0 ordered, 29–48 failures shuffled** — the
  same condition at a third the suite size. So rows leak state into their successors
  somewhere below the per-file boundary busted insulates (`insulate` restores `_G` and
  `package.loaded` per spec file, not mutations to a required module's own tables).
- **Why it stands:** every run anyone makes — local, CI, `busted tests` — is in declaration
  order, so it costs nothing today. Finding the leaks is a suite-wide investigation across
  subsystems that no single feature owns, and it would be started for a property nothing
  currently depends on.
- **Revisit:** before enabling `--shuffle`, test sharding, or any parallel runner in CI —
  each of those turns this from dormant into a source of false failures. Also worth a pass
  whenever a subsystem's fixtures are next reworked, since the leaks are fixture-shaped.

### Editor submit raises when no buffer is open

- **Where:** `src/view/editor/editorView.lua` `get_current_buffer` — `local bm =
  ctrl:get_active_buffer()` is indexed unguarded on the next line.
  `EditorController:get_active_buffer` is `self.model.buffers:first()`, which answers
  **nil** when the buffer list is empty. Two more call sites index the same nil the same
  way: `get_active_buffer_id` and `_generate_status`.
- **State:** reproduced deterministically, not observed once. The harmony scenario
  `editor.open-close` — `project("create")`, `edit()`, then **Ctrl+Shift+S** — raises
  `editorView.lua:70: attempt to index local 'bm' (a nil value)` through
  `editorController.submit` ← `_normal_mode_keys` ← `keypressed`. The buffer list is empty
  at the moment the key is handled; **why** it is empty right after `edit()` on a freshly
  created project is *not* diagnosed here.
- **Not a feature regression:** the full scenario suite was run against two trees — with and
  without the input feature's in-flight widget-lifetime change — and produced the same error,
  at the same line, once each, in logs of identical length. It predates that work.
- **Why it is filed and not fixed:** it is outside the input subsystem and outside the
  feature that found it; fixing it means deciding what submit *should* do with no buffer
  (no-op, or refuse earlier), which is an editor design call.
- **No test covers it.** `busted tests` is green, so the suite never submits without a
  buffer — the gap is what let a deterministic raise sit unnoticed in a scenario that runs
  every time the harmony suite does.
- **Revisit:** when the editor's buffer lifecycle is next touched. A guard in
  `get_current_buffer` alone would only move the nil one frame later; the three call sites
  and the "what does submit mean here" question go together.

### The console's terminal self-test is unreachable

- **Where:** `src/controller/consoleController.lua` — `terminal_test`'s opening guard,
  `love.state.app_state ~= 'ready' or love.state.app_state ~= 'project_open'`. A state
  cannot be both, so the disjunction holds for every value and the function always returns
  before its body.
- **State:** the whole feature is dormant. `Ctrl+Alt+T` in DEBUG does nothing;
  `util/test_terminal.lua` is never called, so `love.state.testing` is never set and its
  readers — the `'running'` / `'waiting'` branches in `ConsoleController:keypressed` and
  `src/view/input/statusline.lua` — cannot fire. Present at the PR base `3256aac`, so it
  pre-dates the input-API branch and no current work touches it. The intent reads as `and`.
- **Why it stands:** a developer-facing self-test with no caller in normal use; nothing
  observable regressed when it stopped running, which is why it went unnoticed. Fixing the
  operator re-animates a display path nobody has exercised in months — worth doing
  deliberately, with a look at the output it paints, rather than as a drive-by.
- **Revisit:** when the console's debug affordances or the terminal widget are next worked
  on. Fix is one operator; the work is confirming the revived path still renders sensibly.

### `string.split_array`'s type guard never fires

- **Where:** `src/util/string/string.lua:241` —
  `if not type(str_arr) == 'table' then return {} end`.
- **State:** operator precedence makes this `(not type(str_arr)) == 'table'`,
  which is `false == 'table'`, i.e. **always false**. The guard never returns
  early, so a non-table argument reaches `ipairs(str_arr)` and raises there
  instead of being handled. The intended form is `type(str_arr) ~= 'table'`.
- **Why it matters beyond the typo:** `string.lines` delegates every list to
  this function, and `UserInputModel:set_text` delegates to `string.lines`, so
  the guard sits on the input widget's content path. It is **latent, not live** —
  every current caller passes a table — which is why this is BACKLOG.
- **Provenance: pre-existing**, another author's utility module. Found by the
  cold peer review, 2026-09-01, while checking how a non-string
  element is handled.
- **Not slugged**, and **no size refactor implied** — the fix is the two
  characters that make the guard mean what it says.

### `table.protect(love.handlers)` is a no-op on the passed table

- **Where:** `src/controller/controller.lua` — end of `setup_callback_handlers`.
- **State:** `table.protect` returns a read-only proxy but does not mutate the original
  table; the call's return value is unused, so `love.handlers` is not actually protected.
- **Why it stands:** No observed breakage, and the proxy-vs-mutate semantics are a broader
  `util/table` question.
- **Revisit:** If/when read-only enforcement on `love.handlers` is actually wanted — either
  consume the returned proxy or change `table.protect`'s semantics.

### The imported editor rework changes three view files that nothing on this branch can smoke

- **Where:** `src/view/editor/bufferView.lua` (+46/−1), `src/view/input/userInputView.lua`
  (+10) and `src/view/input/statusline.lua` (−1) — the drawing changes that arrived with the
  editor rework imported at `21eb7f53`. Re-derive with
  `git diff --stat af9a5782 f4cf338c -- src/view/` → **3 files, +55/−2**
  (`af9a5782` is the base the rework was taken against, `f4cf338c` its head).
  Second half of the same gap: `doc/development/smoke_checklists.md` has **no step that
  enters the platform's own editor**. `grep -in editor doc/development/smoke_checklists.md`
  returns hits that are all the maze project's *editor level* — a game level whose widget is
  the project's, not the platform editor's buffer view.
- **State:** the suite runs headless against `mock_love`, with no display, so a drawing
  change can neither fail it nor pass it. `busted tests` green at 1123 / 0 / 0 / 10 is
  silent about all three files: a stale, clipped or mis-drawn frame is invisible to every
  automated check this repository has. Nothing here is a known defect — the point is that
  *known* is not available, in either direction, until a human looks at a screen.
- **Why it stands:** the rework's surface is its author's to smoke, and this branch imported
  it rather than wrote it. Writing checklist steps for it means stating what those frames
  are *supposed* to look like, which is the rework author's product knowledge and not ours;
  inventing our own expectations would smoke our guesses rather than their design.
- **Revisit:** when the device smoke passes are next run on real hardware — that is the only
  instrument that can clear this, and the pass should meet it as a decision (run an editor
  section, or record that the imported surface ships unsmoked and by whose call). Also
  revisit if this branch itself edits any of the three files, which would make the residual
  ours rather than the rework author's.

## RETIRED

### T-EPHEMERAL-IDS — the persistent ledgers cite sprint ids that only resolve inside the working tree (RESOLVED, 2026-09-21)

- **RESOLVED at `DOC-01-06` (session107), and the "0–2" expectation below was FALSIFIED.** The
  control sweep expected 0–2 mechanical leftovers; it found **162**. The theory that the compaction
  and vacuum passes strip the class incidentally did not hold — the ledger-editorial standard
  (`DOC-01-02`/`-03`) deliberately **kept** sprint ids as provenance rather than stripping them, so a
  "step finding dozens means an earlier pass failed" reading is wrong here: no pass failed, the
  expectation was mis-set. The owner ruled the **full sweep** (2026-09-21). All ~150 de-citeable
  sites were reworded to state their referent inline (or point at a shipping `conventions/` doc)
  across `decisions/input.md`, `technical_debt/input.md`, this file, `smoke_checklists.md`,
  `internals/user_input.md`, `internals/examples/turtle.md`, plus the one code comment already done
  at `DOC-01-10`. The command's prefix list was widened to add `COMMENT` (missed since the freeze,
  like `SIMPLE`/`PROP`). The widened sweep now returns only the two exempt regions — this entry's own
  illustrations and `conventions/docs.md`'s rule-statement. The command below stays runnable so the
  two docs-review passes (`DOC-01-08`/`-09`) and the slice cut can re-check that no id crept back;
  their rows already carry the *no-new-ids* constraint. **The account and command below are kept as
  the historical record.**
- **Why it mattered:** the ids resolve **only** in the tree that names them, and that tree is
  deleted or kept whole by an owner ruling at assembly time. If it goes, every citation reads as a
  live pointer to a sprint the reader cannot find — the failure mode worse than dangling, because
  it **greps clean**.
- **Re-derive (do not quote a total — see below):**
  `git grep -oE '\b(ACC|ARC|LEDGER|FEAT|BUG|FIX|CHG|DEC|OP|REC|MERGE|PR)-0[0-9](-[0-9]{2})?\b'
  -- doc/ ':!doc/development/wip/'`. Snapshot 2026-09-03 at `d90b3fd6`: **118 matches** (116
  citations + two exempt `conventions/docs.md` illustrations), concentrated in
  `technical_debt/input.md`, this file, and `decisions/input.md`. **No total is citable for this
  class**: describing it requires naming sprint ids, so every edit to the entry emits more of what
  it counts — the 2026-09-04 figure was rewritten three times and wrong twice within the hour. The
  command and the file-level shares are the stable measure, not a number.
- **Scope widened to `src/` and `tests/` (owner ruling, 2026-09-21).** Comment prose and doc prose
  share one discipline; a sweep is split doc/-vs-code **only** for size, never to shrink scope. The
  re-derive above scanned `doc/` alone, and the omission let sprint-id citations sit unswept in code.
  It must run over `src/`/`tests/` too, and its prefix list — frozen at the 2026-09-03 snapshot —
  needs the sprints minted since (`SIMPLE`, `PROP`, `DESIGN`, `EDKEYS`, `SHOWN`, `FLAGS`, `SHOW`,
  `PAYLOAD`, `ROUTE`, `DOC`, `PREX`, `COMMENT`):
  `git grep -nE '\b(ACC|ARC|LEDGER|FEAT|BUG|FIX|CHG|DEC|OP|REC|MERGE|PR|PROP|DESIGN|EDKEYS|SHOWN|FLAGS|SHOW|PAYLOAD|SIMPLE|ROUTE|DOC|PREX|COMMENT)-[0-9]{2}(-[0-9]{2})?\b' -- doc/ src/ tests/ ':!doc/development/wip/'`.
  **session106 ran this over code and cleared the three it found** — `SIMPLE-01`, `SIMPLE-01-05` and
  `SIMPLE-01-06` in `tests/input/input_simple_surface_spec.lua`, reworded to state the point inline
  (`492e50e5`). `DOC-01-06` inherits the widened command.
- **Distinct from two rows that look like it.** The retired-id sweep takes citations of ids already
  **dead**; these are all **live and correct today**. And the ephemeral-**path** rule this shares
  its logic with never covered bare ids, which is why the count reached three figures unflagged.
- **The sibling path class is closed and PAID** (2026-09-06). A persistent ledger never cites `wip/`;
  only the reverse is allowed. Six live citations written after the
  2026-09-03 sweep were removed — **none deleted**; each entry now **states the evidence it used to
  point at** (the attestation and who gave it, the sorted-line proof behind *"the reshape changed no
  executable content"*, `REC-01`'s measurement as a dated fact, `R11` as a named risk class).
  Re-derive with
  `git grep -nE '(wip/77|77-new-input-api|design/|validation/|implementation/|pr-slices|pr-assembly|sessions/session|ROADMAP\.md|plan\.md)' -- doc/ ':!doc/development/wip/'`;
  it should return only the six `LEDGER-02` holds plus this entry's own illustrations (**a path
  citation does not have to spell the path**). **A class stays closed only while something re-runs
  its command** — three sessions cited freely between 2026-09-03 and 2026-09-06 because the ledger
  said it was shut.
- **What is left under the pattern is not citation, and must not be swept as if it were:** this
  entry's own illustrations, which must spell the paths they forbid; and the `LEDGER-02` holds,
  **RESOLVED** entries whose *"Where"* records a fixed defect's location (the subject, not a
  pointer). §3 vacuums those to the archive anyway. **`DOC-01-06` should expect to find nothing to
  rewrite here and something to move.**
- **Provenance: ours, entirely.** At the PR base `3256aac` neither the ledgers nor the ids exist.
- **Found:** 2026-09-03, re-deriving the citation-hygiene rows, which had measured paths only.
- **Scheduled as a control step, late and on purpose** (owner ruling 2026-09-03/04). The rule
  landed immediately (`conventions/docs.md`, *Rules*) so new prose does not add to the pile; the
  **sweep runs after the compaction pass and the two ledger-vacuuming passes** (`DEC-02`,
  `LEDGER-02`), because a vacuumed entry takes its ids out with it and most citations are the
  troubleshooting trail compaction eliminates by eliminating what it annotates. The pre-PR gate a
  proposal asked for was **merged into the sweep** rather than added as a second instrument: it runs
  with the expected result of **nothing to do** — the ledger share of hits held ~90% across three
  re-derivations, and those leave with their entries — so no interval is left for the class to
  regrow. A step that expects zero and finds dozens means an earlier pass did not run; that is the
  check.
- **One residue was structural, not narration — `smoke_checklists.md` was *keyed* by sprint ids.
  PAID 2026-09-04 (session73, at `FIX-02-09`).** Its device-pass table used `ACC-02-01…-05` as the
  **row identifiers**; compaction could not have cleared this, because the id *was* the structure —
  a structural key is exactly what the renumber-vs-rename rule warns against, arriving in a shipped
  checklist. The rows
  are now keyed by the list's own name (`balloons`, `keyboard`, `maze`+`draw`, `sapper`, `turtle`),
  a plain 1–5 left for reading order. The residue that remains is narration, which compaction
  clears — `smoke_checklists.md` (three `FEAT-02`, prose), `internals/user_input.md` and
  `internals/examples/turtle.md` (one each), plus the exempt `conventions/docs.md` illustrations.

### The persistent corpus cited the rule chain, and the rule chain does not ship (RESOLVED, 2026-09-21)

- **The hazard:** the persistent corpus carried citations of `agents/…` — a chain the release omits
  — so each read as authoritative but would resolve to nothing once `agents/`, `AGENTS.md` and
  `CLAUDE.md` were dropped from the cut.
- **Paid by the `agents/` lift (session107),** in the two moves the owner's 2026-09-06 ruling set out
  (*"lift anything permanently useful into `doc/` first, then omit `agents/`"*):
  - **Lift.** The durable, code-facing conventions moved into `../conventions/` as prose, each
    marked *suggested* (owner, 2026-09-21): the 16-line function-body tolerance, "No invented
    special cases", and "don't over-fix" into `code.md`; a new `testing.md` (breaking-test-first,
    tests drive real code, mock only genuine boundaries); a new `commenting.md` (the comment-content
    discipline); and a new `ledgers.md` recommending the two ledgers stay active. **The three
    communication-register rules — *Presenting Decisions and Questions* (the one candidate the row
    had named), the analytic-notes tone, and stakeholder summaries — were judged
    workflow-assumption-laden and NOT lifted** (owner ruling, 2026-09-21).
  - **Repair.** Every citation of the chain from the shipping corpus was reworded to **state the
    rule inline**, or to point at the lifted `conventions/` doc that now ships: sites across this
    file, `decisions/input.md`, `technical_debt/input.md`, `README.md`, and one code comment
    (`src/controller/userInputController.lua`). `conventions/docs.md`'s statement of the rule
    remains by design (the rule explaining itself).
- **The omission itself executes at the slice cut** — it drops `agents/`, `AGENTS.md` and
  `CLAUDE.md`, which that row already records (its `Set 2` question is moot, not answered). With the
  corpus no longer citing the chain, the omission ships no dangling reference.
- **Provenance: ours.** Neither the rule chain in this shape nor these registers exist at the PR
  base `3256aac`. **Found:** 2026-09-03; **resolved:** 2026-09-21.

### T-NEVER-SHIPPED — the register kept entries for defects that never existed outside the branch (RESOLVED, 2026-09-12)

- **The rule:** what a branch introduced and paid before
  release never existed for anyone outside it, so its entry records our own working process rather
  than the product's history. A **pre-existing** defect the branch fixed is the opposite: it
  shipped, users met it, and the entry is the evidence behind a changelog line.
- **Classification (do not re-derive):** the base-classification pass tested every retired entry against the PR base
  `3256aac`, verifying its resolution claim and answering *did this exist at the base?* in one pass.
  The verdict over the walked 56 was **39 introduced-in-branch · 9 pre-existing · 5 mixed ·
  3 cannot-tell**; five more entries retired outside that snapshot were all **introduced-in-branch**
  and not close — their subjects (`CHANGELOG.md`, `doc/input_api.md`, this register, `auto_hide`)
  are this feature's or absent at base. The durable half of the fix: any entry retired after
  2026-09-05 is classified by the session that retires it, so the gap does not reopen.
- **Executed in sessions 95–96.** The introduced-and-paid entries were **moved** to
  `validation/archive/debt-vacuumed.md` — a wip record that leaves the release; nothing in it rules
  anything (`ledgers.md` §2, §8). The **9 pre-existing** stayed (changelog evidence — they
  shipped, users met them). The **5 mixed** were rewritten to their pre-existing/shipped half in
  place and their introduced half archived (`T-CURSOR-BYTES` is the worked example).
  The **3 cannot-tells** — the `maze`/`balloons` entries, whose repos have no comparable base
  commit — stayed, since the rule vacuums what is known to be ours and not what is merely unproven.
  `T-DRIFT-PR45` stayed as **not-ours** (upstream #45; the debt was the distance to it).
- **One introduced-and-paid entry was KEPT by owner ruling (2026-09-12): `T-NAV-ESCAPE`.** A live
  `BACKLOG` entry, `T-EDITOR-KEYS-DEFAULT-OPEN`, cross-references it as its worked instance (as did
  `T-BLOCK-AT-OPEN`, `RESOLVED` earlier on this branch), so it stays resolvable in the register — the
  `ledgers.md` depth rule over vacuuming, the same call session95 made for *"Pointer delivery is an
  unstructured broadcast"*.
- **Resolved 2026-09-12** (this entry's Revisit). Self-contained: it depends on no
  entry that has since moved to the archive.


### T-DRIFT-PR45 — this branch does not sit on the editor rework it will ship beside (RESOLVED, 2026-09-05)

- **Where:** the platform repo. Our branch and the upstream editor-rework pull request
  (*"Editor rework: explicit modes, line navigation, durable accepts, undo/redo"*, head
  `16eb33d7`) share a base of 2026-07-09 and have diverged since. The rework is **52 commits, 20
  files, +3018/−377** across `src/` and `tests/`; **11 of those files are ones this branch also
  changed**.
- **State:** the two are **compatible, and this is measured rather than argued.** A trial merge in
  a throwaway clone, resolved and run, gives **1100 passing / 22 failing** where this branch alone
  gives 1055/0 and the rework alone gives 753/0. **No failure is in the `compy.input` surface** —
  the public API, the routing grid, the hooks and shortcuts tables, the widget's configuration and
  every non-editor lifecycle case pass unchanged.
- **Blast radius — the editor route's key semantics, and nothing wider.** The rework introduces
  explicit navigation/editing submodes, so typing no longer inserts by default; it rewrites Enter
  handling around block accept; it redefines Escape; and it reassigns the Ctrl+S family. Six of
  this branch's specs pin the behaviour it replaces. Five of those are **re-pins** — the rework is
  entitled to change them — and exactly one is a genuine two-answers-one-key conflict: **bare
  Ctrl+S in the editor**, which closes the buffer here and is reserved for the rework's checkpoint
  there.
- **What it costs, itemised:** one **integration point** — the rework reaches into the framework's
  power-shortcut block, which this branch restructured into a privileged reservation table, so its
  editor reservations become entries in that table; one **mechanical signature merge** on the input
  model's constructor, which both sides changed; one **key-meaning decision** (bare Ctrl+S); one
  resolution of the editor controller, whose rewrite is a superset of our edits there; and **five
  spec re-pins**. It also **forces a repeat of the on-device pass** for anything that types in the
  editor, because the keys move.
- **Settled by measurement, not preference:** `set_text` was rewritten by both sides. Keeping ours
  and adding the rework's one-line history reset gives 1100/22; taking theirs gives 1094/28, the six
  extra being this branch's own content contracts. **Keep ours.** The two test harnesses are also
  **not interchangeable** — adopting the rework's `tests/mock.lua` wholesale adds 145 errors here
  and fixes none of its own failures.
- **Provenance: not ours.** Upstream work by another author, on its own timeline.
- **Revisit: it is release work, not deferred debt.** The decision of record (2026-09-03) is to
  build on the rework so the two ship together.

**Resolution (2026-09-05).** The import landed and the tree is **green at
1123 / 0 / 0 / 10**. Every itemised cost above was paid, and three of the entry's own figures
were wrong by the time it was executed — which is the transferable part, not the outcome:

- **The head it names is gone.** `16eb33d7` was force-pushed away; 52 commits became **9 on top
  of `dev`**, and the content moved with them (4 files, +317/−327). The **four conflicts and the
  resolution table survived unchanged**, so the entry's analysis held even though its
  measurements did not.
- **"1100 passing / 22 failing" was an artifact of the trial's probes**, which took one side
  wholesale in two files. Resolving those two deliberately gave **6** failures, and all six
  closed: one was a mechanics break in *their* spec (a widget that is never shown takes no
  keys), and five were ours to re-pin.
- **"Five spec re-pins" and "one integration point" were both off.** The re-pins were five, but
  one of them turned out to be a **behaviour change rather than a renaming** and is now
  `T-NAV-ESCAPE`. And there was **no integration point at all**: the rework's editor
  reservations did *not* need to enter our `RESERVED` table — expressing them there contradicts
  `D-EXACT-RESERVE`'s own scope, and the correct resolution leaves `controller.lua`
  **byte-identical to its pre-merge state**.
- **The key-meaning decision was taken as filed**: bare Ctrl+S is the rework's, ours no longer
  closes the buffer, leaving is `Shift+Esc` and `Ctrl+Shift+S`.

**Provenance: NOT OURS** — upstream work by another author, and the debt was the
distance to it. Classified here per `T-NEVER-SHIPPED`'s rule that an entry retired after
2026-09-05 is classified by the session that retires it.


### T-NAMESPACE-CLONE — a live platform table in a namespace travels to the project as a copy — PAID by a written practice

- **The hazard is generic and pre-existing.** The project environment is a deep clone taken
  before the run (`../internals/project_sandbox_env.md`). A live table placed in a namespace as
  a plain field is *copied* into that clone, so the program assigns its handlers into the copy
  while the dispatcher reads the original, and **neither side raises** — nothing is nil, nothing
  is logged, the handlers simply never run. It binds any subsystem handing a project a live
  table, not the input surface.
- **Paid by:** `../conventions/architecture_principles.md`, *"A Namespace Hands Out Live
  Tables by Reference, Never by Value"*. Filed as a **suggested practice rather than a
  decision** (owner, 2026-08-30) on two grounds: the rule is generic, and a table that is
  genuinely a snapshot may be passed by value quite correctly, so the right instrument is a
  practice with a question attached (*does anyone write to this after the run starts?*), not a
  ruling. `decisions/input.md` D-FROZEN-SHELL carries the one-line pointer to it;
  D-ONE-STATE-ASK records the same hazard met from the other direction
  (`love.state.user_input` read inside a project is always `nil`).
- **Retired 2026-08-30.** Nothing outstanding: the obligation was documentation, and the code
  already implements the pattern. How each in-tree surface dodges the hazard is the branch's
  own working detail and is vacuumed.
