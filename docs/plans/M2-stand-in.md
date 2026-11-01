# M2 · Moving together while dragging

**Goal:** the two windows move together without visible lag, as pictures in one window of Pairwise's own.
**ADRs:** 0024, 0025, 0026, 0027, 0028, with 0014 for the picture and parking

Not in this milestone: joining, the shared seam, coming apart, choosing a partner, restoring. Those are M3.

## Tasks
- [x] `PairwiseCore`, test-first: which on-screen window matches a frame, where a partner is parked, the protocols and errors.
- [x] `PairwiseTestSupport`: a fake stand-in and a capture a test finishes by hand.
- [x] `PairwiseUI`, test-first: `FollowModel` swaps to the stand-in, parks the partner, puts it back at the release, and falls back to following.
- [x] `PairwiseWindowSystem`: the capture and the panel; ScreenCaptureKit confined there by `tools/check_dependencies.sh`.
- [x] The app: the Screen Recording status and button, the new measurement; `nl` and `de` in the catalog.
- [x] A test of whether a window drag can be held back (ADR 0023).
- [x] One window of Pairwise's own while dragging (ADR 0024).
- [x] The other ways of following removed (ADR 0028).

## Acceptance criteria
- [x] `tools/build.sh verify` is green.
- [x] By hand: the two windows move together while dragging without visible lag, and the owner's verdict is in `docs/reference/spike-following.md`.
- [x] By hand: the real windows are out of sight during the drag (the assumption of ADR 0014), and end level and tight after the release.
- [x] Measured and written down: how long the panel takes to appear, and how its moves hold up.
- [x] The stress test moves both windows every time (ADR 0027).
- [x] `tools/build.sh ci` is green (when the owner says so, ADR 0011).

## Trying it
`tools/build.sh run`, allow Accessibility and Screen Recording, quit and run again, press Start, open a window of the partner app, and drag a window of another app by its title bar. `tools/build.sh run --drag-stress-test <file>` makes the app test itself; it takes over the pointer while it runs.
