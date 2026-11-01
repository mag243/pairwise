# M1 · Spike: following the pointer

**Goal:** decide, with numbers and by hand, whether a partner moved through the Accessibility API from the pointer is smooth enough, or whether M2 (the stand-in) is needed.
**ADRs:** 0012, 0013

Not in this spike: joining, the shared seam, coming apart, choosing a partner, restoring. Those are M3.

## Tasks
- [ ] Sign debug builds with Apple Development (ADR 0012).
- [ ] `PairwiseCore`, test-first: the grip, the partner's place, what counts as a window drag, the measurements, and the protocols of the window system.
- [ ] `PairwiseTestSupport`: a fake window system.
- [ ] `PairwiseUI`, tested against the fake: `FollowModel`, the press, follow and release of ADR 0013.
- [ ] `PairwiseWindowSystem`: the Accessibility API and the listen-only event tap behind Core's protocols.
- [ ] The app: permission status, Start and Stop, the last drag's numbers; `nl` and `de` in the catalog.
- [ ] `docs/reference/spike-following.md`: where the measurements go.

## Acceptance criteria
- [ ] `tools/build.sh verify` is green.
- [ ] By hand: the permission stays granted after a rebuild.
- [ ] By hand: dragging a window moves a Finder window beside it, and the partner ends level beside it after the release.
- [ ] Measured and written down: at least 60 moves per second on a Finder window, with the duration of a move and the points behind.
- [ ] The owner's verdict is in `docs/reference/spike-following.md`: smooth enough, or on to M2.
- [ ] `tools/build.sh ci` is green (when the owner says so, ADR 0011).

## Trying it
`tools/build.sh run`, grant Accessibility in System Settings when asked, press Start, open a Finder window, and drag another window by its title bar.
