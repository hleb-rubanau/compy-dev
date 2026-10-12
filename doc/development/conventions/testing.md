# Testing Conventions

<!-- authored By LLM; human-approved NOT YET -->

> Suggested conventions — not fully fixed; they evolve with experience. Some are
> unique to this project by design.

---

## Start with a breaking test

Write the test that fails **first**, then make it pass by implementation. A test
authored after the code it checks tends to assert what the code happens to do; a
test authored before it asserts what the code is *for*. The failing run is the
proof the test can fail at all — a test that has never been red is not yet known
to be testing anything.

---

## Every test exercises real production code

A test drives a real production code path and asserts on its **observable
behaviour or output**. Never write an "empty" test that stubs or mocks the unit
under test and then only asserts the mock was called: it passes without the real
code running, so it pins nothing and protects nothing.

**Mock only genuine boundaries** — I/O, the `love2d` runtime, external systems.
Those are the seams the test cannot cross and should not try to. Everything
inside the boundary is the thing under test and runs for real.
