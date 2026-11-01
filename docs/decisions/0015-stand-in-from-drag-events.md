# 0015. Moving the stand-in on drag events, and raising the partner

- **Status:** Superseded by 0028
- **Date:** 2026-11-01
- **Milestone:** M2

## Context
The owner's first run of the stand-in (ADR 0014): a little lag remains, the partner sometimes stands a small distance from the dragged window, and after the release the partner is behind another window, while the stand-in floated above everything.

## Decision
- **Drag events move the stand-in.** The event tap also listens to the left mouse button being dragged, and each such event moves the stand-in at once, so a move no longer waits for the next tick. The tick stays, for parking and for when events stop coming. ADR 0013 rejected following from drag events because a slow call to another app would queue stale positions; a stand-in's move does not call another app. Without a stand-in the partner still moves on ticks only.
- **The gap is measured before it is fixed.** The report holds how far the place worked out from the grip was from the dragged window's real place at the release. A large number means the grip is off; a small one means the gap was lag while moving.
- **The partner is raised at the release,** after it is in place and before the stand-in comes down, through the Accessibility raise action, so it stays in front as the stand-in was. **Assumption, to confirm by hand:** this raises it above other apps' windows without taking focus from the dragged app. A failed raise is not reported, since the partner is in its place.

## Alternatives
- **Activating the partner's app:** surely brings it forward, but takes focus from the app the user is working in. Kept for if the raise is not enough.
- **Keeping the stand-in at the partner's place in the window order:** needs the order of other apps' windows while dragging, and the partner would still be hidden behind them.
- **Changing the grip now:** the cause of the gap is not known yet.

## Consequences
- Positive: a stand-in's move comes at most one event behind the pointer, not up to one tick behind it.
- Negative / risks: moves per second now follows the mouse's event rate, so it is no longer comparable with M1. The dragged window is moved by the window server, so a frame of lag may remain.
- Changes now: `PointerButtonEvent`, the tap, `MovableWindow`, `FollowModel`, the report and the app's window.
