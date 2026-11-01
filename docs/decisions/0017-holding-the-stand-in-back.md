# 0017. Holding the stand-in back

- **Status:** Superseded by 0018
- **Date:** 2026-11-01
- **Milestone:** M2

## Context
The owner sees a gap appear when dragging toward the stand-in. A stand-in that lagged would overlap in that direction, so it runs ahead: Pairwise sees the pointer before the window server has moved the dragged window, and since ADR 0015 it moves the stand-in at once. No API tells when the dragged window reaches the screen, so the difference cannot be measured from inside the app.

## Decision
The stand-in goes where the pointer was a short, fixed time ago, not where it is now. In the spike the time is set in the app's window, in steps of 4 ms, so the owner can find the right value by eye; it starts at one frame at 60 Hz, 16 ms. The log holds the value of each drag. The partner's place at the release still comes from the real frame.

## Alternatives
- **Going back to moving on ticks only:** adds a delay of up to one tick that varies, and it cannot be adjusted.
- **A value worked out from the display's refresh rate:** may be right in the end, but needs the measured value first.

## Consequences
- Positive: the delay can be matched to the dragged window, by eye.
- Negative / risks: the right value may differ per display or per app. The setting is for the spike; M3 has to choose a fixed value or a rule.
- Changes now: a pure rule in `PairwiseCore`, `FollowModel`, the app's window and its strings.
