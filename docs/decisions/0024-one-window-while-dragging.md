# 0024. One window of Pairwise's own while dragging

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M2

## Context
A stand-in beside a window macOS drags can never keep step with it, as the two move on separate schedules. The test of ADR 0023 showed that withholding drag events stops a window drag, and the owner confirmed that clicks keep working. So Pairwise can do the moving itself.

## Decision
- **A press in the top band of another app's window** passes, and starts on a picture of both that window and its partner. Drag events from that press on are withheld.
- **When the pointer has moved 3 points and the pictures are there,** one panel shows both pictures side by side, with the partner on the right and their tops level. Both real windows are then parked out of sight (ADR 0014), and each drag event moves the panel by the pointer's movement. The panel and the pointer need no other app, so the two pictures cannot drift apart.
- **At the release,** the dragged window goes to the panel's place, the partner goes beside the window's actual place, both are raised with the dragged window on top, and then the panel comes down. A busy app is tried again for half a second, as in ADR 0014.
- **It fails open.** Without the Screen Recording permission or a partner nothing is held. If the pictures fail or take over a second, the drag events pass again. A tick checks the button itself, so a lost release still ends the drag. A stop or quit puts both windows back.
- **The stand-in beside the window stays for now** as a separate mode, to compare by eye. The owner then chooses. The test of ADR 0023 has done its work and goes.

## Alternatives
- **Letting the real dragged window move until the pictures are there:** the window would jump back into a panel, and macOS's snapping would be in play. Holding from the press keeps it still.
- **Keeping the real dragged window visible under the panel:** nothing to park, but its edges would show around the picture.
- **Moving on display ticks:** drag events come at least as often, and need no reading of the pointer.

## Consequences
- Positive: no gap or overlap between the two while dragging, no slip, and no snapping against other windows.
- Negative / risks: both windows are still pictures during a drag, with a short wait at the start and a swap at each end. A crash during a drag leaves two windows parked. The band is a fixed height, so a drag starting there on a tab or other control does nothing. Windows snapping to screen edges and tiling are lost during such a drag. Whether a drag can go on after the events pass again is not known.
- `PairwiseWindowSystem` gains more code that needs real windows; the coverage gap stays for M3.
- Changes now: the window system protocol, the panel, the capture, a new model, the app's window and its strings.
