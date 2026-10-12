# Keeping the Ledgers Active (suggested)

<!-- authored By LLM; human-approved NOT YET -->

> A **suggested** practice, not a ruling. The ledger topology described here was
> invented during one feature's development; whether the project keeps it is the
> project's call. This doc recommends keeping it, and says why.

---

The project carries two per-subsystem ledgers under `doc/development/`:

- [`technical_debt/`](../technical_debt/README.md) — known debt, discovered
  during work and deliberately not fixed at the time it surfaced;
- [`decisions/`](../decisions/README.md) — the durable *why* behind each
  subsystem's shape.

Their shape is documented in each directory's `README.md`: entries carry short
uppercase slugs (`T-` for debt, `D-` for decisions) so they are greppable and
citable from code; debt moves through **ACTIVE → BACKLOG → RETIRED** in
release-scope order; a paid or reversed entry is **moved to RETIRED, not
deleted**, so the trail survives.

**The recommendation: keep both ledgers active as the codebase evolves.** The
value is not in the entries a single feature left behind — it is in the standing
habit:

- **Debt stays visible instead of vanishing.** "Report, don't fix on the spot"
  (see [`code.md`](code.md)) only works if the report has a home that outlives the
  commit that made it. The register is that home.
- **Decisions keep their rationale.** When a later reader asks "why is it built
  this way rather than the obvious other way", the answer is written down rather
  than reconstructed from git archaeology.
- **Code can cite durable rationale.** A `D-` slug in a comment resolves to an
  argument that ships, not to a working tree that was deleted.

A ledger left to ossify as an artifact of the feature that started it loses all
three. The suggestion is simply that new subsystems get their own ledger files
and that entries keep moving through their lifecycle rather than freezing.
