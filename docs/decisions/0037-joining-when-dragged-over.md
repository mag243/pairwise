# 0037. Joining when dragged over the other window

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
ADR 0035 joins a window only when its edge is within 24 points of the other's opposite edge. The owner dragged a Terminal window towards a Finder window with Command held, and nothing happened. The log shows the press was recognized, and no place to join was found. Dragging a window over the one it should join is the natural movement, and it passes straight through such a narrow band.

## Decision
A window can join another when it is within 24 points of it or overlaps it at all. The side follows from the centres: right of the other's centre is its right side. Among several windows the closest edge wins, as before. The end of a joining drag is logged with whether a place was found.

## Alternatives
- **A wider snap distance only:** the window still has to stop short of the other, and a wide band snaps from far away.
- **Overlap up to half the other's width:** a narrow window in the middle of a wide one would then join nothing, and that is where it lands when dragged onto it.

## Consequences
- Positive: dragging onto a window joins it, and the guide shows it before the release.
- Negative / risks: with Command held the drag joins more readily, which suits a key meant for joining.
- Changes now: `JoinRule`, the model's log.
