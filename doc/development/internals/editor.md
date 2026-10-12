# Editor — Implementation Overview

<!-- authored By LLM; human-approved NOT YET -->

## The Core Concept: Block-Centric Editing

The editor does not operate on lines. For Lua files, it operates on **blocks** — top-level syntactic units produced by the metalua chunker. A block is either a `Chunk` (one or more source lines forming a complete top-level statement/expression) or an `Empty` (a blank separator line). The selection highlight, navigation, submit, delete, insert, and move operations all act on blocks, not on individual lines.

For plain text and Markdown files, the model falls back to line-level editing — each line is its own "block".

This distinction pervades the entire editor stack. Understanding it is the prerequisite for understanding anything else here.

---

## Content Types and Buffer Initialization

`EditorController:open()` (`src/controller/editorController.lua:48`) determines content type from the file extension and wires up the right tools:

| Extension | Content type | Tools |
|---|---|---|
| `.lua` | `lua` | metalua chunker, pretty-printer, truncer, highlighter |
| `.md` | `md` | markdown highlighter only |
| anything else | `plain` | none |

A `BufferModel` (`src/model/editor/bufferModel.lua`) is created with these tools and immediately tries to chunk the file content. **If the initial Lua parse fails, the buffer is marked `readonly = true`** and the selection is set to 1. The file is viewable but nothing can be edited or saved — this prevents corrupting a file that the editor cannot parse.

**On open, the buffer selects the first block** (`sel = 1` in `bufferModel.lua`; the selection can later be walked to the last with `move_selection`). This is PR #45's behaviour, imported faithfully: before the import the editor opened with the **last** block selected. Nothing reverses it — but it is a real behaviour change, so navigation written against the old selection (an `up` that used to walk from the last block) no longer moves from the top of the document.

After construction, `lateinit` calls `analyze()` immediately to populate semantic info.

---

## The Input Widget's Role

The editor does not have its own widget — it reuses `UserInputModel` / `UserInputController` / `UserInputView`, the same widget as the console REPL. The input strip at the bottom is how you type content to put into the buffer.

The workflow is:
1. Navigate the buffer selection to the block of interest
2. Press `Esc` to **load** the selected block's text into the input
3. Edit in the input
4. Press `Enter` to **submit** the input back, replacing the selected block

`Shift+Esc` inserts the block text into the input at cursor rather than replacing it (additive load).

The `LuaEditorEval` evaluator (`src/model/interpreter/eval/evaluator.lua:168`) is set on the editor input for Lua files. It adds a 64-character line length validator — the same limit as the code conventions — enforced live as you type.

**`input_max` vs `LINES`** — two separate height limits. `input_max = 14` is the input strip height, used as the `VisibleContent` `size_max` in `UserInputModel` and to calculate the physical pixel height of the input widget. `LINES = 16` is the buffer viewport height. `input_max = 14` was deliberately chosen to match the code convention (function body ≤ 14 lines): a conforming block fills the input view exactly, with no scrolling needed.

The monster block fix (`2ff95f03`) uses `bufv:get_max_size()` — which returns `LINES = 16` — as the submission rejection threshold. This means the editor currently accepts blocks of up to 16 lines, which is inconsistent with the convention and with `input_max`: a 15- or 16-line block passes the oversize check but violates the style limit and cannot be fully seen in the input strip without scrolling. The correct threshold would be `input_max` (14). `BufferView` has access to `self.cfg` so `get_max_size()` could return `self.cfg.input_max` instead of `self.LINES`.

---

## The `loaded` Tracker — Why It Exists

`BufferModel.loaded` records which block index was most recently loaded into the input. This prevents a specific foot-gun: if you load block 3, then navigate the selection to block 7 (the highlight moves), then press Enter, you don't want to overwrite block 7 with what you loaded from block 3.

The submit handler checks `buf:loaded_is_sel(true)`. If the currently selected block is not the one that was loaded, the submit instead re-selects the loaded block and scrolls to it, giving you a chance to confirm. Only if selection and loaded agree does the replace proceed.

This is the most important non-obvious invariant in the editor interaction model.

Source: `BufferModel:set_loaded`, `loaded_is_sel`, `select_loaded` (bufferModel.lua:516–545); the check in `_normal_mode_keys` → `submit` → `replace` (editorController.lua:647–669).

---

## The Submit Pipeline (Lua Mode)

Pressing `Enter` on non-empty input goes through `_handle_submit` (editorController.lua:321), which is more involved than it looks:

1. **Pretty-print** — the raw input text is passed through `parser.ast_to_src` (metalua's printer). The displayed result may differ from what was typed (spacing, indentation, end-placement). If pprint fails, the original is used as fallback. `ast_to_src` behaviour is covered by `tests/interpreter/analyzer_spec.lua`, which is its primary specification.
2. **Re-chunk** — the pretty-printed result is chunked again to get the actual block structure that will be stored.
3. **Empty preservation** — if the raw input had a leading or trailing `Empty` block but the pretty-printed version does not, those empties are restored. This preserves the user's intentional blank-line spacing.
4. **Empty injection** — if two consecutive non-empty chunks emerged from the pretty-print, an `Empty` is inserted between them. Enforces the "at most one blank line" format rule at the model level.
5. **Oversize check** — if any resulting block exceeds the size limit (currently `bufv:get_max_size()` = `LINES` = 16, though the intended limit is `input_max` = 14 — see the `input_max` vs `LINES` note in the Input Widget section above), the submit is rejected. The cursor moves to line 1 of the offending block; no error message.
6. **Replace or Insert** — `replace_content` or `insert_content` updates the buffer, adjusting all subsequent block positions via `Range:translate`.
7. **Auto-save** — `buf:save()` is called immediately. Every accepted submit writes to disk.

`Ctrl+Enter` inserts the new block(s) before the selection rather than replacing it.

---

## Monster Blocks

A block with more source lines than the editor's size limit is a **monster block**. These can exist in files written outside the editor or imported. The editor handles them without data loss:

- **Viewing** — monster blocks are displayed in the buffer normally; content beyond the visible window is scrolled.
- **Loading** — pressing Escape loads the full block into the input model, even though only `input_max` (14) lines are visible in the input strip at once. The rest is reachable by scrolling the input.
- **Visibility tolerance** — the submit handler uses `bufv:is_selection_visible(true)` (the oversize-tolerant variant) when checking whether to proceed. A monster block whose start line is at the top of the visible range is considered "visible enough" to edit, even though it extends beyond the bottom.
- **Submitting** — the submitted content is chunked. If all resulting chunks are within the size limit, they replace the monster block (effectively splitting it). If any chunk is still oversized, that chunk is rejected and the cursor moves to its first line (`reject_oversized`).

The practical editing pattern: load the monster block, edit it into valid code that chunks into conforming-size pieces, submit. Multiple resulting chunks each become their own block in the buffer, with empty separators injected between consecutive non-empty ones (step 4 of the submit pipeline).

**Note on the current size limit:** the oversize threshold here is `bufv:get_max_size()` = `LINES` = 16, not the intended `input_max` = 14 — so the editor accepts 15–16 line blocks that violate the convention and need input scrolling to view. Full explanation in the `input_max` vs `LINES` note in the Input Widget section above.

Source: commit `2ff95f03b8f8` ("Split monster block"); logic in `editorController.lua:_handle_submit` and `bufferView.lua:is_selection_visible`.

---

## Block Position Tracking

Each `Chunk` carries a `pos: Range` recording which source lines it occupies (e.g. `{3-7}` means lines 3 through 7). When blocks are inserted, deleted, or replaced, all subsequent blocks have their `pos` adjusted by the line delta. This is done manually in `replace_content` and `insert_content` — there is no automatic re-sync; it is purely arithmetic on the stored ranges.

This matters because the revmap (source line → block index), used for semantic info, is rebuilt only on `analyze()`, which runs on `buf:save()`. Between saves, the revmap may be stale. In practice this is fine because semantic info is only used at search time, which always follows a save in the normal workflow.

---

## The Two Visible Content Types

The view layer has two parallel implementations for the visible slice of a buffer:

**`VisibleContent`** (`src/view/editor/visibleContent.lua`) — used for plain/md files. Wraps the raw line array at the configured character width, manages a scroll offset/range over the resulting wrapped lines. Straightforward.

**`VisibleStructuredContent`** (`src/view/editor/visibleStructuredContent.lua`) — used for Lua. Must handle blocks, where each block wraps independently. Each block becomes a `VisibleBlock` (`src/view/editor/visibleBlock.lua`) that holds its own `WrappedText` and pre-maps syntax highlighting through wrap breaks.

Text in the editor passes through three coordinate spaces (documented with a worked example in `doc/development/editor/visible.md`):

1. **Normal coords** — original source line numbers, as stored in the file
2. **Wrapped coords** — apparent lines after word-wrapping at screen width; a single long source line may produce multiple wrapped lines
3. **Visible coords** — the subset of wrapped lines currently in the scroll window

For Lua buffers, each block has **two position fields** tracking the first two spaces:
- `pos` — the block's position in source lines (normal coords)
- `app_pos` — the block's position in wrapped/apparent lines (what the view uses for rendering and scroll)

These diverge whenever any block has lines longer than the screen width. Scrolling, selection visibility, and line number display all operate in apparent-line space; source queries (semantic info, revmap) operate in source-line space. The mapping between them is maintained in `VisibleStructuredContent.reverse_map` and recalculated in `recalc_range()`.

The `WrappedText` base class (`src/util/wrapped_text.lua`) provides the three-table mapping structure: `wrap_forward` (source line → list of display lines), `wrap_reverse` (display line → source line), `wrap_rank` (display line → its offset within the wrap break sequence). These are used for cursor coordinate translation in the input and for highlight remapping in `VisibleBlock`.

---

## Editor Modes

The editor has three modes managed in `EditorController.mode`:

**`edit`** (default) — normal editing. Navigation, load, submit, delete all active.

**`reorder`** (Ctrl+M) — block move mode. The current selection is saved as `state.moved`. Navigation moves the selection (the visual highlight) while the "picked up" block index stays in `state.moved`. Enter confirms the move: `buf:move(moved, target)` physically reorders the block in the dequeue, rechunks, and saves. Escape cancels and restores state.

**`search`** (Ctrl+F) — definition search. The buffer's `semantic.definitions` (all assignments found by the analyzer) are loaded into `Search`. As you type, `Search:narrow()` filters the list with a case-insensitive substring match (lowercase input = case-insensitive, mixed = case-sensitive). Enter jumps to the selected definition's block and scrolls to its first line.

Transitions are one-directional: from any special mode, only a return to `edit` is allowed (no reorder→search transitions). This is enforced in `set_mode`.

---

## Semantic Analysis

`BufferModel:analyze()` runs on every `save()`. It:
1. Rechunks the current text (to get a fresh AST)
2. Runs `analyzer.analyze(ast)` which walks the AST and collects assignments (global/local/function/method/field) and `require()` calls with their line numbers (`src/model/lang/lua/analyze.lua`)
3. Builds `revmap` (source line → block index) from block positions
4. Converts the flat `SemanticInfo` into `BufferSemanticInfo` which replaces line numbers with block indices

This gives the editor two capabilities:
- **Search** (Ctrl+F): filter and jump to definitions by name
- **Follow require** (Ctrl+O): if the selected block contains a `require('foo')` call, open `foo.lua` as a new buffer on top of the stack

`analyze()` is wrapped in `pcall` — analysis failure is silent and leaves `self.semantic = nil`, disabling search and follow-require for that buffer.

---

## Buffer Stack and File Navigation

`EditorModel.buffers` is a `Dequeue<BufferModel>` used as a stack (front = active). `EditorView.buffers` is a parallel table keyed by buffer ID (the Lua table address as a string — not the filename). The two stay in sync manually.

Opening a file (`EditorController:open`) pushes a new buffer to the front and tells the view to create a new `BufferView` for it. **Shift+Esc** in nav mode (through `discard` → `close_buffer`) pops the front buffer and activates the next one. If only one buffer remains, it closes the editor entirely and returns to the console. (Bare `Ctrl+S` does nothing in the editor since the PR #45 import — it is the stop-run reservation; the editor is left with `Shift+Esc`.)

Ctrl+O (`follow_require`) calls `self.console:edit(name)` which triggers a full new `open` call, pushing another buffer. This creates a chain: file A → file B → file C, navigable back with Shift+Esc.

The buffer ID ensures the view can retrieve the right `BufferView` even after the model stack changes order. `EditorView.buffers` is never pruned during a session — views for closed buffers remain in the table but are unreachable via the controller once the model buffer is popped.

---

## Key Files

| File | Role |
|---|---|
| `src/controller/editorController.lua` | All input handling, mode transitions, submit pipeline |
| `src/model/editor/bufferModel.lua` | Buffer state, block operations, loaded tracker, save, analyze |
| `src/model/editor/content.lua` | `Chunk` and `Empty` block types |
| `src/model/editor/editorModel.lua` | Model aggregate (input, buffers, search) |
| `src/model/editor/bufferSemanticInfo.lua` | Converts SemanticInfo line numbers to block indices |
| `src/model/editor/searchModel.lua` | Search state, narrowing, scroll |
| `src/controller/searchController.lua` | Search keyboard handling |
| `src/view/editor/bufferView.lua` | Scroll, selection visibility, draw orchestration |
| `src/view/editor/visibleContent.lua` | Scroll/wrap for plain/md |
| `src/view/editor/visibleStructuredContent.lua` | Scroll/wrap for Lua blocks |
| `src/view/editor/visibleBlock.lua` | Per-block wrap + highlight remapping |
| `src/util/wrapped_text.lua` | Core wrap tables (forward/reverse/rank) |
| `src/model/lang/lua/analyze.lua` | AST walker producing SemanticInfo |
| `src/model/interpreter/eval/evaluator.lua` | Evaluator types including LuaEditorEval |
