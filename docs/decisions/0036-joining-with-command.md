# 0036. Joining with Command

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
ADR 0035 started with Option and said its clash with macOS was to be judged. The join test (ADR 0027) shows the clash: the guide stands in the right place, but at the release macOS tiles the window over half the screen (862 by 1010 points), over the place Pairwise has just given it. This was seen with a posted Option key.

## Decision
The key is Command, read at the press, for joining and for parting; everything else stays as in ADR 0035. Dragging a title bar with Command is ordinary on the Mac: it moves a window without bringing it forward, and it is not known to tile.

## Alternatives
- **Keeping Option and placing the window after macOS has tiled it:** a window that jumps twice, and a fight with macOS.
- **Control:** a press with Control counts as a right click.
- **Shift:** from memory, macOS uses it during window drags as well.
- **Fn:** not on every keyboard in reach, and awkward to hold while dragging.

## Consequences
- Positive: to be confirmed by the join test and by hand.
- Negative / risks: with Command a dragged window stays behind others until the release, so it can be hidden from view while joining; the release raises it. Command works on a title bar, and a Command-click elsewhere in an app has meanings of its own, which a press outside a drag leaves alone since all its events pass.
- Changes now: the window system, the app's strings, the join test. The rest of ADR 0035 stands, which is why it is not superseded.
