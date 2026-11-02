# 0053. Not losing windows

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
During a drag and a resize at the seam, both windows of a pair are parked out of sight (ADR 0024, 0049). If Pairwise crashes or is killed then, they stay there, and a user has no way to get them back. The panel with their pictures goes away with the process.

## Decision
- **Before parking, the two windows' numbers, their processes and their frames are written to a file** in the app's folder in Application Support, in one atomic write. The file is removed once the windows are back in place.
- **At the next start, with the Accessibility permission, Pairwise puts back the windows in that file,** with their size and place, and removes it. Without the permission the file stays until it can be used.
- **A window is put back only if it can still be the same window:** the record is from this boot of the Mac, and a window with that number belongs to the same process. A number can come back after a restart of the Mac or of the app, and no other window may move. A window that has gone is skipped.
- A file that cannot be read is removed. Nothing can be done with it, and it must not stop the app.
- **A kill test** in the debug build opens two windows of its own, parks them in a drag, kills the app, and a second run checks where they ended.

## Alternatives
- **A helper process that watches the app:** puts windows back at once, not only at the next start, but it is a second program to install and keep alive. It can still come, along with starting at login.
- **Not parking:** ADR 0049 parks to keep the real windows from showing through.
- **Recording every window's place all the time:** far more than is needed.

## Consequences
- Positive: a crash during a drag loses no window, as long as Pairwise is started again.
- Negative / risks: until the next start the windows stay out of sight. A window moved by hand in between is moved back. Pairs themselves are not restored (step 9), and a resize in progress goes back to its size at the press.
- Changes now: `PairwiseCore` (`ParkingRecord`), the window system, the model, the fake, the stress test, the plan.
