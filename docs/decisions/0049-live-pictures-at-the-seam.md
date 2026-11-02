# 0049. Live pictures at the seam, with the windows parked

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
ADR 0048 showed still pictures at the seam, with the real windows under the panel. By hand, the owner saw the real windows through the pictures, and streaks where a still picture has to fill much more room than it has. Both need the real content, at about its real size, and nothing under the panel.

## Decision
- **Both windows are parked once the panel shows,** as with moving (ADR 0024), so nothing shows through. At the release they come back, at their exact places.
- **Under the panel, each look only resizes.** The places do not matter while parked, so this is one call per window instead of two. The looks are 20 a second, as the live pictures show the windows' real width.
- **While a seam moves, each picture shows the window's live frames,** at the frame rate of the setting. Set to still, the pictures stay still, as in ADR 0048.
- **A stream at the seam has room for the pair's whole width,** and does not scale, so a window that grows needs no change of the stream. Each frame says which part of it holds the window. This is to be checked on real frames.
- **A frame fills its picture's whole place, scaled to fit.** It differs little from that place, as the window follows the seam, so the scaling hardly shows. A still picture keeps its division until the first frame comes.
- **The still picture of a window's top left stays over its live frames,** as macOS shows a mark of its own in the frames of a window it streams, in place of the close, minimize and zoom buttons. A window with no such buttons there shows that corner still.
- The rest of ADR 0048 stands: the seam at the pointer, the limits, the release.

## Alternatives
- **Changing the stream's size as the window changes:** each change takes time, and frames of the old size keep coming meanwhile.
- **The division of a still picture for frames too:** tried first. By hand, it showed as a line with half letters through a terminal, also with a still pointer, as a terminal rounds its width to whole characters and so nearly never fits.
- **Opaque pictures with the windows left in place:** a see-through window would show wrong, and nothing would save the second call per look.

## Consequences
- Positive: the content moves with the seam, with no line through it, and what is scaled shrinks to the distance the window lags behind.
- Negative / risks: two streams with room for the whole pair take more memory and time than a move does. Calls to the apps run on the main thread at 20 a second, which may show as hitches. An app that does not draw while parked shows a still picture.
- Changes now: `WindowStandIn`, `StandInPanel`, `LiveStream`, `LivePicture`, the model, the fake, the plan.
