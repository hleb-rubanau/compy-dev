# Technical Debt Register

A running list of known debt — discovered during work but deliberately not addressed at
the time it surfaced. Entries are matter-of-fact context, not defects to fix on sight; each
notes where it lives, why it stands, and when it is worth revisiting.

**Every `ACTIVE` entry carries a `T-` slug** — a short uppercase mnemonic on a `T-` prefix, capped at
16 characters, declared **first in the heading** with the prose after it. That is what a roadmap row
cites when it points at the goal it is working towards, and it makes the whole class greppable
(`grep -rn '\bT-[A-Z]'`). The shape deliberately matches the decisions ledger's `D-` slug, and the
prefix keeps the two apart for good.

An entry **earns its slug when it becomes `ACTIVE`, and keeps it afterwards.** `BACKLOG` and
`RETIRED` entries are read rather than cited, so slugging all of them would be ceremony: unlike a
decision, a debt entry is not cited from `src/` or `tests/`.

Each file sorts its entries into three sections, in release-scope order — not severity, not
intent: **ACTIVE** must be resolved before the current release ships. **BACKLOG** is real
and acknowledged debt, but deliberately deferred past the current release. **RETIRED** is
paid, or turned out not to be debt — moved there, not deleted, with its heading's resolution
marker kept intact.

Tone and intent follow
[`../conventions/architecture_principles.md`](../conventions/architecture_principles.md): state
what is, matter-of-factly and without a blame register — the audience built the system and knows
its trade-offs.

This register is organised **per subsystem** — one file per area, so a new subsystem gets
its own ledger instead of growing a single flat list.

## Index

- [`general.md`](general.md) — debt not specific to one subsystem (load-order/aliasing
  assumptions, shared utility semantics).
- [`input.md`](input.md) — the input subsystem: keyboard/text/pointer routing, the console
  and project input controllers, and the `compy.input` project-facing surface.
