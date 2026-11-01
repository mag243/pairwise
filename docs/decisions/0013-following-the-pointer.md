# 0013. How the spike follows the pointer

- **Status:** Superseded by 0028
- **Date:** 2026-11-01
- **Milestone:** M1

## Context
M1 answers one question: does a partner window moved through the Accessibility API, from the pointer, feel smooth enough? an earlier project's spike (an earlier spike) found that moves are reported about ten times a second, that reading the pointer with the grip kept from the start of the drag gives the window's place at once, and that the only reliable end of a drag is the mouse button coming up. Its XCUITest drags did not move windows.

## Decision
- **Watching.** A listen-only event tap sees the left mouse button go down and up, and nothing else. It cannot hold up or change input.
- **A drag is a window that moved.** At the press Pairwise notes the window under the pointer and its frame. While the button is down it reads that frame: when the origin has changed and the size has not, this is a window drag. This holds for title bars and toolbars of any height, and it leaves clicks and resizes alone. It costs the first frame or two of a drag.
- **Following.** From then on, 120 times a second, the dragged window's place comes from the pointer and the grip, without asking the other app, and the partner is moved beside it with its top level. A timer runs only while the button is down.
- **The end.** At the button's release the partner is placed from the dragged window's real frame, since the system can stop a window where the pointer would not (the menu bar).
- **The partner is simple:** the first standard, not minimized Finder window that is not the dragged one, always on the right. Choosing partners is M3.
- **One thread.** Everything runs on the main actor, so `AXUIElement` never crosses an isolation boundary and no `@unchecked Sendable` is needed. A call to a slow app can hold up the main thread for at most the messaging timeout; input is not held up, because the tap only listens.
- **Measuring.** Per drag: moves per second, the duration of one move (mean, 95th percentile, longest) and how far the pointer travelled during a move (mean, most), in the window and in the log.

## Alternatives
- **A fixed title bar height:** wrong for toolbars, and it would follow for a press that never moves the window.
- **Following from drag events:** a slow call would leave a queue of stale positions.
- **A separate thread for the Accessibility calls:** would keep the window responsive, but needs an isolation design a spike does not justify.

## Consequences
- `PairwiseCore` has its own small geometry types (`ScreenPoint`, `WindowSize`, `WindowFrame`): Foundation alone exposes `CGPoint` and `CGRect` without initializers or equality, which come from CoreGraphics, and Core imports only Foundation (ADR 0001). `PairwiseWindowSystem` converts.
- The spike's own strings are few, so they are translated directly in the catalog; the translation tools of ADR 0010 come over with M3, which adds real text.
- `PairwiseWindowSystem` is thin code around calls that need the permission and real windows, so plain tests do not reach it. Its 75 % coverage target is not met in M1, and `tools/build.sh coverage` says so; the target stands, and M3 meets it with a seam around the system calls.
- No UI test drives a drag: it would need the permission and, by an earlier project's finding, would not move the window. Feel is judged by hand.
