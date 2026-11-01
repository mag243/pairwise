# M1 · Spike: following the pointer

**Goal:** decide, with numbers and by hand, whether a partner moved through the Accessibility API from the pointer is smooth enough, or whether M2 (the stand-in) is needed.
**ADRs:** 0012, 0013

Not in this spike: joining, the shared seam, coming apart, choosing a partner, restoring. Those are M3.

## Tasks
- [x] Sign debug builds with Apple Development (ADR 0012).
- [x] `PairwiseCore`, test-first: the grip, the partner's place, what counts as a window drag, the measurements, and the protocols of the window system.
- [x] `PairwiseTestSupport`: a fake window system.
- [x] `PairwiseUI`, tested against the fake: `FollowModel`, the press, follow and release of ADR 0013.
- [x] `PairwiseWindowSystem`: the Accessibility API and the listen-only event tap behind Core's protocols.
- [x] The app: permission status, Start and Stop, the last drag's numbers; `nl` and `de` in the catalog.
- [x] `docs/reference/spike-following.md`: where the measurements go.

## Acceptance criteria
- [x] `tools/build.sh verify` is green.
- [x] By hand: the permission stays granted after a rebuild.
- [x] By hand: dragging a window moves a Finder window beside it, and the partner ends level beside it after the release.
- [x] Measured and written down: at least 60 moves per second on a Finder window, with the duration of a move and the points behind.
- [x] The owner's verdict is in `docs/reference/spike-following.md`: smooth enough, or on to M2.
- [x] `tools/build.sh ci` is green (when the owner says so, ADR 0011).

## Trying it
`tools/build.sh run`, press Grant Access… and allow Pairwise in System Settings, press Start, open a Finder window, and drag a window of another app by its title bar. Quit and run again when the pointer cannot be watched right after granting. Pairwise's own window is ignored.
