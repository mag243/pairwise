# 0014. A stand-in while dragging

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M2

## Context
M1's verdict: a partner moved through the Accessibility API keeps the timer's 120 moves a second, and it still visibly lags behind, since the other app and the window server handle a move after the call returns. A window of Pairwise's own has no other app in the way. `PLAN.md` names the route: a picture of the partner in a window of Pairwise's own, with the real partner out of sight until the release.

## Decision
- **The picture.** ScreenCaptureKit takes one picture of the partner, without its shadow, when a drag is seen. The on-screen window is found by its app, its size and the origin closest to the partner's frame, since the Accessibility API gives no window number without a private call.
- **Until the picture is there,** the partner follows as in ADR 0013. The capture takes time, so the drag shows the old lag for its first moments, and the swap may be seen. Capturing at the press would avoid that, but every click would then take a picture.
- **The stand-in.** A borderless, non-activating panel that ignores the mouse, floating above normal windows, so it never takes focus or clicks from the app being dragged. It shows first, at the partner's place, so nothing flashes.
- **Out of sight.** No Accessibility attribute hides one window, and minimizing animates. The partner is parked at the bottom right corner of all displays, with one point left on screen. **Assumption, to confirm by hand:** the system lets it go there.
- **The release.** The real partner goes to its place from the dragged window's real frame, then the stand-in comes down. A busy app is tried again on later ticks, up to half a second, with the stand-in in place, because a partner left parked looks lost. After that the stand-in comes down and the problem is reported. Any other failure brings it down at once. A stop or quit during a drag also puts the partner back.
- **Without Screen Recording, or when the picture fails,** the partner follows as in ADR 0013, and the app shows why. Dragging keeps working.
- **Measuring.** The report also holds how long the stand-in took to appear after the drag was seen, and its moves are the moves measured from then on.

## Alternatives
- **Moving the partner under the stand-in:** nothing to park, but the lagging window would stick out from behind the picture.
- **Getting the window number through `_AXUIElementGetWindow`:** exact, but a private call, which would close the Mac App Store route (open decision 3).
- **Refusing to follow without Screen Recording:** clearer, but it takes away what works without that permission.
- **Live video of the partner:** shows changes during the drag, but costs far more for a drag of a few seconds.

## Consequences
- Positive: the partner should move as fast as Pairwise's own window. Whether it looks right is judged by hand.
- Negative / risks: a second permission, which macOS asks about again from time to time. The partner is a still picture during a drag. A crash during a drag leaves the partner parked in the corner.
- `PairwiseWindowSystem` gains more code that needs permissions and real windows, so the coverage gap of ADR 0013 grows. The seam stays in M3. The pure rules (which window matches, where to park) are in `PairwiseCore` and tested.
- Changes now: the window system protocol, `FollowModel`, the fake, the app's window and its strings; ScreenCaptureKit is confined to `PairwiseWindowSystem` by `tools/check_dependencies.sh`.
