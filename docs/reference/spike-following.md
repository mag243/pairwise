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
