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

**Does the permission survive a rebuild?** Yes: across many rebuilds Pairwise stayed on under Accessibility and the terminal stayed off, confirmed by the owner.

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
| Not noted, picture at the press, held back 16.7 ms | 266 | 154.4 | 0.17 | 0.54 | 4.5 |
| Not noted, picture at the press, held back 16.7 ms | 1855 | 185.9 | 0.16 | 12.32 | 1.7 |
| Not noted, picture at the press, held back 16.7 ms | 1144 | 208.7 | 0.17 | 0.53 | 0.9 |
| Not noted, picture at the press, not held back | 1696 | 222.8 | 0.19 | 4.82 | 1.5 |

The largest grip offset with a still pointer, in the same order for these last four drags: 84.0, 52.8, 33.5 and 82.6 points. It does not follow the hold-back.

Following the window server's place (ADR 0018), moves per second is how often that place changed, and a move includes reading it:

| Dragged window | Moves | Moves per second | Mean move (ms) | 95th percentile (ms) | Longest move (ms) | Stand-in after (ms) | Most slip (points) |
|---|---|---|---|---|---|---|---|
| Not noted | 940 | 54.3 | 2.64 | 5.02 | 18.34 | 2.4 | 49.5 |
| Not noted | 153 | 60.4 | 1.77 | 5.27 | 11.38 | 4.4 | 35.7 |
| Not noted | 305 | 56.0 | 2.43 | 6.32 | 12.33 | 1.8 | 22.6 |

Looking ahead (ADR 0019), with the place's changes and the pointer's together in moves per second:

| Look ahead (ms) | Moves | Moves per second | Mean move (ms) | 95th percentile (ms) | Longest move (ms) | Stand-in after (ms) | Most slip (points) |
|---|---|---|---|---|---|---|---|
| 16 | 896 | 90.5 | 3.27 | 5.32 | 15.17 | 1.2 | 37.1 |
| 56 | 442 | 99.7 | 1.64 | 7.35 | 8.62 | 1.6 | 41.6 |
| 4 | 501 | 98.6 | 2.16 | 7.46 | 9.91 | 1.5 | 57.3 |
| 60 | 377 | 104.6 | 2.22 | 4.09 | 13.57 | 1.4 | 36.5 |
| 8 | 669 | 102.7 | 3.00 | 5.39 | 11.35 | 6.3 | 81.4 |
| 0 | 281 | 79.0 | 1.27 | 2.24 | 8.49 | 1.3 | 46.6 |
| 8 | 352 | 97.4 | 1.39 | 2.98 | 13.81 | 1.9 | 27.7 |
| 4 | 418 | 90.3 | 1.81 | 5.02 | 10.25 | 1.3 | 19.5 |
| 12 | 241 | 94.3 | 2.11 | 3.71 | 9.25 | 1.4 | 14.6 |
| 8 | 319 | 93.1 | 1.97 | 3.37 | 12.20 | 1.5 | 21.9 |
| 8 | 184 | 85.6 | 1.33 | 2.15 | 11.21 | 0.5 | 34.7 |

Comparing the two (ADR 0020), both looking ahead 8 ms:

| What moves | Moves | Moves per second | Mean move (ms) | 95th percentile (ms) | Longest move (ms) | Most slip (points) |
|---|---|---|---|---|---|---|
| Picture | 453 | 97.2 | 1.74 | 7.76 | 9.31 | 53.5 |
| Real window | 1281 | 97.4 | 2.39 | 4.63 | 12.36 | 42.8 |
| Real window | 758 | 84.4 | 2.14 | 3.30 | 10.84 | 28.1 |

In step with the display (ADR 0021), with and without prediction:

| Look ahead (ms) | Predicting | Moves | Moves per second | Mean move (ms) | 95th percentile (ms) | Longest move (ms) | Stand-in after (ms) | Most slip (points) |
|---|---|---|---|---|---|---|---|---|
| 8 | Yes | 551 | 112.5 | 3.24 | 6.39 | 15.88 | 0.8 | 46.3 |
| 8 | Yes | 1348 | 97.9 | 3.23 | 6.77 | 10.61 | 1.3 | 48.0 |
| 8 | No | 356 | 102.8 | 3.39 | 6.38 | 11.97 | 0.6 | 29.7 |
| 8 | No | 160 | 101.5 | 3.21 | 5.39 | 8.02 | 1.7 | 15.6 |
| 24 | Yes | 623 | 88.7 | 3.84 | 7.21 | 9.74 | 0.5 | 57.5 |
| 4 | Yes | 330 | 112.5 | 3.13 | 4.95 | 8.72 | 1.2 | 13.8 |
| 60 | Yes | 328 | 100.0 | 3.74 | 7.35 | 13.85 | 0.4 | 20.0 |
| 12 | Yes | 509 | 107.9 | 3.06 | 4.85 | 6.83 | 1.3 | 65.4 |
| 12 | No | 242 | 107.1 | 3.72 | 7.27 | 7.48 | 2.1 | 49.5 |

Holding back a drag (ADR 0023): the pointer ended 13.7 points from the press with 65 events withheld, and the window moved 0 points.

One window while dragging (ADR 0024). "Panel after" runs from the press, so it includes any wait before the pointer moves:

| Moves | Moves per second | Mean move (ms) | Longest move (ms) | Panel after (ms) |
|---|---|---|---|---|
| 751 | 105.5 | 0.30 | 1.80 | 223 |
| 16 | 86.1 | 0.26 | 1.36 | 74 |
| 428 | 104.8 | 0.40 | 2.39 | 246 |
| 416 | 89.4 | 0.37 | 0.97 | 1084 |
| 549 | 81.3 | 0.36 | 0.69 | 1537 |
| 301 | 90.1 | 0.37 | 2.28 | 2018 |

**By hand, first run:** a little lag remains, the Finder window sometimes stands a small distance from the dragged window, the swap is not seen, and after the release the Finder window is behind another window. ADR 0015 answers these.

**By hand, second run, on drag events:** less lag, with a short delay at the start of a drag. While dragging, the stand-in sometimes stands a small distance from the dragged window and sometimes overlaps it; after the release the two are tight. ADR 0016 answers these.

**By hand, direction:** the owner sees a gap open when dragging toward the stand-in, so it runs ahead of the dragged window. ADR 0017 answers this.

**By hand, third run:** while the gap or overlap grows, the pointer and the stand-in move and the dragged window stands still until it jumps along. Without Pairwise running, the pointer also sometimes shifts against the place where a Terminal window was held. So the place worked out from the pointer and the grip is not always where the window is, which ADR 0013 assumes.

**By hand, following the window server:** the stand-in and the window move together, with a small delay. The owner saw that the pointer moves first and the window follows shortly after. ADR 0019 answers this.

**By hand, looking ahead:** 4 to 8 ms looks best, and a visible effect remains.

**The owner asks what the stand-in adds,** since it knows the window's place as late as a real partner. ADR 0020 compares the two.

**By hand, comparing with Finder as the partner:** the difference is very small. The picture may be a little smoother, and that is very hard to see. What remains is the check with a slower app than Finder (ADR 0020).

**The owner's choice:** the stand-in stays, without the check with a slower app.

**By hand, predicting:** no positive effect, at any look-ahead tried. ADR 0022 drops it.

**By hand, holding back a drag (ADR 0023):** while the test runs, windows cannot be dragged by their title bars, so withholding drag events stops a window drag. Clicks keep working.

With the window list kept and the pictures taken together, over 13 drags: the pictures came after 41 to 83 ms, before the pointer had moved 3 points each time, and no drag passed without them. The panel came after 101 to 484 ms, with one each at 913 and 2155 ms, moves took 0.28 to 0.39 ms on average, and the longest took 6.09 ms.

**By hand, moving as one:** when dragging starts straight after the press, only the held window moves. After a short wait the other window comes along, and then it looks very smooth.

**By hand, moving as one, after taking the pictures faster:** dragging straight after the press now works every time and looks smooth.

**By hand, moving as one, later:** pressing at a new place on the title bar and dragging at once sometimes moves only the held window; after a short wait both go along every time. A small flash at the release, not very noticeable.

**From the log of that run:** 11 presses gave "no window under the pointer", within about a millisecond and in clusters, so those drags were not taken over. ADR 0026 answers this. Deciding on the other presses took 5 to 32 ms.

**From the log after ADR 0026's first version:** every press gave "no window under the pointer", and the partner never followed. That version stopped at the first window of any level. It now looks only at the normal level.

**From the log after the window server's list:** every drag that reached the panel was fine, but some presses show "released with no panel" about 4 ms after the press, with the button still down. The tap sees a press before the system counts the button as down, so the check for a lost release ended those presses, and their drags passed. This matches the owner's report that sometimes only the held window moves. Fixed with a failing test first.

**The stress test (ADR 0027), 40 drags of Finder windows with posted events:** with the button check as fixed, both windows moved 40 times out of 40. With the fault put back for one run, both moved 11 times, only the held window 25 times, and nothing 4 times. So the test catches this fault, and the symptom is the one the owner reported.

**Is the real partner out of sight during the drag?** Not answered yet.

**Verdict:** not given yet.
