# 0019. Looking ahead with the pointer's movement

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M2

## Context
Following the window server's place (ADR 0018), the stand-in moves together with the dragged window, with a small delay: it can only go where the window has already been. The owner noticed that the pointer moves first and the window follows it shortly after, so the pointer tells where the window is going.

Following the pointer's place itself failed: when the window slips from the pointer, the stand-in stays off by that much (ADR 0018). The pointer's movement over a short time does not carry that error.

## Decision
The stand-in goes to the window server's place of the dragged window, plus how far the pointer moved in the last moments. When the pointer rests, this adds nothing, so the stand-in comes to rest exactly beside the window. When the window hangs while the pointer moves, the stand-in is ahead by at most the pointer's movement in that short time, and it does not run away.

In the spike the time looked ahead is set in the app's window, in steps of 4 ms, so the owner can find the right value by eye; it starts at one frame at 60 Hz, 16 ms. The log holds the value of each drag. Only a stand-in looks ahead: a partner moving as itself lags far more, for another reason (ADR 0013).

## Alternatives
- **Extending the window's own recent movement:** needs no pointer, but reacts later, and overshoots when the window stops.
- **Moving a share of the way to the pointer's place:** keeps a share of the slip as a lasting error.
- **Accepting the small delay:** the simplest, and what a look-ahead of 0 ms gives, for comparing.

## Consequences
- Positive: the delay can be matched by eye, and resting beside the window stays exact.
- Negative / risks: too large a value makes the stand-in run ahead and overlap or leave a gap, and a sudden stop or turn can show. The right value may differ per display or per app; M3 has to choose a fixed value or a rule.
- Changes now: a pure rule in `PairwiseCore`, `FollowModel`, the app's window and its strings.
