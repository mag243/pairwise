# Spike: following the pointer

Measurements and verdict of M1 (ADR 0013). The numbers are the app's "Last drag", also in the log (subsystem `me.m-domain.pairwise`, category `follow`).

Measured on 2026-11-01. The partner is a Finder window, and the dragged windows were not noted.

| Dragged window | Moves | Moves per second | Mean move (ms) | 95th percentile (ms) | Longest move (ms) | Mean points behind | Most points behind |
|---|---|---|---|---|---|---|---|
| Not noted, first process | 809 | 120.0 | 0.88 | 1.77 | 7.57 | 0.03 | 6.4 |
| Not noted, first process | 629 | 120.1 | 1.07 | 2.04 | 4.64 | 0.12 | 7.3 |
| Not noted, first process | 417 | 120.0 | 1.20 | 2.39 | 6.76 | 1.61 | 17.5 |
| Not noted, first process | 734 | 119.7 | 1.04 | 2.11 | 10.06 | 1.05 | 72.4 |
| Not noted, first process | 122 | 118.9 | 0.95 | 2.19 | 10.37 | 1.31 | 20.9 |
| Not noted, second process | 336 | 120.0 | 1.04 | 2.39 | 5.58 | 0.39 | 8.4 |

**What the numbers show:** the follow timer's 120 Hz is met, so the calls keep up with it. A move is timed until the Accessibility call returns, and "points behind" is how far the pointer travelled during that call.

**What the numbers do not show:** when the partner appears at its new place on screen, or the distance between the two windows. Those are for the eye, which is why the verdict below is the owner's.

**Does the permission survive a rebuild?** Not settled.

**By hand:** the Finder window moves along with the dragged window, and it visibly lags behind.

**Verdict:** not smooth enough. On to M2, the stand-in while dragging.

## The stand-in (M2)

Measured by hand on 2026-11-01 with the stand-in of ADR 0014, with a Finder window as the partner. "Stand-in after" is the time from seeing the drag to showing the picture.

| Dragged window | Moves | Moves per second | Mean move (ms) | Longest move (ms) | Stand-in after (ms) |
|---|---|---|---|---|---|
| Not noted | 660 | 120.1 | 0.18 | 2.11 | 107.8 |
| Not noted | 2021 | 120.0 | 0.15 | 1.79 | 47.9 |
| Not noted, on drag events | 675 | 204.6 | 0.16 | 1.47 | 116.9 |
| Not noted, on drag events | 2399 | 202.7 | 0.17 | 6.81 | 61.9 |
| Not noted, on drag events | 458 | 211.4 | 0.17 | 0.65 | 74.3 |
| Not noted, on drag events | 319 | 204.8 | 0.15 | 0.57 | 54.2 |

**By hand, first run:** a little lag remains, the Finder window sometimes stands a small distance from the dragged window, the swap is not seen, and after the release the Finder window is behind another window. ADR 0015 answers these.

**By hand, second run, on drag events:** less lag, with a short delay at the start of a drag. While dragging, the stand-in sometimes stands a small distance from the dragged window and sometimes overlaps it; after the release the two are tight. ADR 0016 answers these.

**By hand, direction:** the owner sees a gap open when dragging toward the stand-in, so it runs ahead of the dragged window. ADR 0017 answers this.

**By hand, third run:** while the gap or overlap grows, the pointer and the stand-in move and the dragged window stands still until it jumps along. Without Pairwise running, the pointer also sometimes shifts against the place where a Terminal window was held. So the place worked out from the pointer and the grip is not always where the window is, which ADR 0013 assumes.

**Is the real partner out of sight during the drag?** Not answered yet.

**Verdict:** not given yet.
