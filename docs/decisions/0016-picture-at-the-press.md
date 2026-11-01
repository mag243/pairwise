# 0016. The picture at the press, and measuring the grip with a still pointer

- **Status:** Superseded by 0028
- **Date:** 2026-11-01
- **Milestone:** M2

## Context
The owner's second run of the stand-in (ADR 0015): less lag, and a short delay at the start of a drag. The stand-in appeared 54 to 117 ms after the drag was seen. While dragging it sometimes stands a small distance from the dragged window and sometimes overlaps it; after the release the two are tight.

The grip offset of ADR 0015, read at the release, gave 1.6 to 77.5 points. That is far larger than the gap the owner saw, so it probably measures a position the app has not updated yet, not the grip.

## Decision
- **The picture is taken at the press** (this changes ADR 0014), in the background, and is shown as soon as the drag is seen. A picture that arrives later still takes over as before. A press that turns out not to be a drag throws its picture away unseen. ADR 0014 rejected this because every click would take a picture; in M3 only a press on a window with a partner needs one, and the spike accepts the cost until then.
- **The grip is measured while the pointer is still** (this changes ADR 0015). Once the pointer has not moved for a tenth of a second during a drag, Pairwise reads the dragged window's frame once and compares it with the place worked out from the grip; the report holds the largest difference. Near zero means the gap while moving is lag. A larger number means the grip itself is off.

## Alternatives
- **Reading the frame on every tick:** would also measure positions the app has not updated yet.
- **Correcting the grip from the frame during a drag:** the cause is not known yet.
- **Predicting the pointer's next place:** may reduce the lag, and may overshoot. Only worth trying once the grip is known to be right.

## Consequences
- Positive: the stand-in can be there from the first moment the drag is seen. The remaining delay is that of seeing the drag.
- Negative / risks: in the spike every press on another app's window takes a picture of the partner. The picture shows the partner as it was at the press.
- A drag without a pause reports no grip offset, so measuring it takes holding still for a moment during a drag.
- Changes now: `FollowModel`, a pure rule in `PairwiseCore`, the tests that said a click asks for no picture.
