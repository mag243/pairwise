# 0022. No prediction for the stand-in

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M2

## Context
The owner compared the stand-in with and without the prediction of ADR 0021, at several look-aheads, and saw no positive effect. The owner chose the stand-in over the real window (ADR 0020), which leaves the switch for that comparison without a use.

## Decision
- `MotionPrediction` and its switch go. The stand-in follows the window server's place and looks ahead with the pointer's movement (ADR 0018, 0019).
- The switch to turn the picture off goes. Without the Screen Recording permission the partner still follows as itself.
- The display link stays: reading the place once per frame needs no chosen rate. Its own effect was not judged apart.
- The look-ahead setting stays until the owner's verdict on M2, starting at 8 ms.

## Alternatives
- **Keeping the prediction switched off:** code nobody runs, and git keeps it should the idea return.
- **Tuning the prediction's constants further:** no sign that the constants are what stood in the way.

## Consequences
- Positive: less code to keep, and fewer settings.
- Negative / risks: a small visible effect remains while dragging.
- ADR 0021 is superseded, except for the display link.
- Changes now: `PairwiseCore`, `FollowModel`, the app's window and its strings.
