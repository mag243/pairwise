# 0018. Following the window server's place of the dragged window

- **Status:** Superseded by 0028
- **Date:** 2026-11-01
- **Milestone:** M2

## Context
ADR 0013 works out the dragged window's place from the pointer and the grip. The owner saw that this does not hold: the dragged window can stand still while the pointer goes on, and then jump, also without Pairwise running. With a still pointer the app's reported place was up to 84 points from the place worked out. A stand-in following the pointer then runs away from the window, whatever its hold-back (ADR 0017).

The window server knows where a window is, and tells without asking its app and without a permission: `CGWindowListCopyWindowInfo`.

## Decision
- **The dragged window's place comes from the window server** while dragging: for seeing the drag, for following, and for the place at the release. It is read 120 times a second. The stand-in, or the partner without one, moves only when that place has changed, so moves per second is how often the place changed.
- **The pointer and the grip are the fallback** for a window the window server does not tell about, and the app's own frame is the fallback at the press and the release.
- **The window number** is found once for each window, by its app, its size and the closest origin (`WindowMatch`), as the Accessibility API gives none without a private call.
- **Measuring.** The report holds the largest distance between the window server's place and the place from the pointer and the grip, the slip. A large slip shows the window really left the pointer. The duration of a move includes reading the place.
- Drag events and the hold-back go: neither helps when following the window itself. The picture at the press (ADR 0016) and raising the partner (ADR 0015) stay.

## Alternatives
- **The app's frame through the Accessibility API on every tick:** goes through the app, and the place comes late while dragging.
- **Correcting the grip from time to time:** still follows a pointer the window is not following.
- **Predicting the window's next place:** may come later, if a steady lag remains.

## Consequences
- Positive: the stand-in cannot run away from the window; when the window hangs, the stand-in hangs with it.
- Negative / risks: not tried yet is how quickly the window server's place changes during a drag, and how long reading it takes on the main thread. Both are in the report. The stand-in stays up to a tick behind the place it reads, in every direction.
- Superseded: the following of ADR 0013 where the window server tells, the drag events of ADR 0015, the grip measure of ADR 0016, and all of ADR 0017.
- Changes now: `MovableWindow`, `FollowModel`, `PointerButtonEvent`, the tap, the fake, the app's window; `PointerDelay` and `StillPointer` go.
