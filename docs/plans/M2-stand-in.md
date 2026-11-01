# M2 · The stand-in while dragging

**Goal:** the partner moves with the dragged window without visible lag, through a picture in a window of Pairwise's own.
**ADRs:** 0014, 0015, 0016, 0018, 0019, 0020, 0022, 0023 (0013 for the following it builds on)

Not in this milestone: joining, the shared seam, coming apart, choosing a partner, restoring. Those are M3.

## Tasks
- [x] `PairwiseCore`, test-first: which on-screen window matches a frame, where a partner is parked, the protocols and errors.
- [x] `PairwiseTestSupport`: a fake stand-in and a capture a test finishes by hand.
- [x] `PairwiseUI`, test-first: `FollowModel` swaps to the stand-in, parks the partner, puts it back at the release, and falls back to following.
- [x] `PairwiseWindowSystem`: the capture and the panel; ScreenCaptureKit confined there by `tools/check_dependencies.sh`.
- [x] The app: the Screen Recording status and button, the new measurement; `nl` and `de` in the catalog.
- [x] A test of whether a window drag can be held back (ADR 0023).

## Acceptance criteria
- [x] `tools/build.sh verify` is green.
- [ ] By hand: the stand-in moves beside the dragged window without visible lag, and the owner's verdict is in `docs/reference/spike-following.md`.
- [ ] By hand: the real partner is out of sight during the drag (the assumption of ADR 0014), and ends level beside the dragged window after the release.
- [ ] By hand: without Screen Recording the partner follows as in M1.
- [x] Measured and written down: how long the stand-in takes to appear, and how its moves hold up.
- [ ] `tools/build.sh ci` is green (when the owner says so, ADR 0011).

## Trying it
`tools/build.sh run`, press Grant Access… for Screen Recording and allow Pairwise in System Settings, quit and run again, press Start, open a Finder window, and drag a window of another app by its title bar.
