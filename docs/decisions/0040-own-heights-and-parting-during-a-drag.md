# 0040. Own heights, and parting during a drag

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
ADR 0035 gave a joining window the other's height, which the owner found wrong for windows of very different sizes. Parting could only start with Command at the press (ADR 0039), which opens a folder menu on a window's title, while joining works with the key pressed during the drag.

## Decision
- **A window keeps its own height when it joins,** with the tops level. This changes the owner's choice 2 in the M3 plan, at the owner's wish.
- **Command with Shift during the drag gives it the other's height,** and the guide shows this live, as long as the keys are down at the release. Option is not used, as macOS tiles a window released with it (ADR 0036). Whether Shift clashes is to be measured.
- **Command during the drag of a pair parts it.** On the next tick the dragged window goes to where the panel shows it, the partner goes back to where it was at the press, and the panel comes down. From then on the drag events stay withheld, as macOS is no longer dragging, and each tick moves the window to the pointer. While Command stays down it can join another window. Before the panel has taken over, macOS is still dragging, and the events go on passing.
- Calls to the apps stay on ticks, as a call on an event would hold up all input.

## Alternatives
- **A menu item for equal heights:** an extra click, and it needs a pair to point at. It can still come.
- **A window staying at the height where it was let go:** nothing jumps, but pairs look uneven.
- **Letting macOS resume the drag after parting:** not known to be possible once its events were withheld.

## Consequences
- Positive: joining and parting work the same way, and a join changes no window's size unless asked.
- Negative / risks: a parted window lags the pointer, as its app carries out each move. Tops level can put the bottom of a tall window off the screen.
- Changes now: `JoinRule`, `PointerButtonEvent`, the tap, the model, the fake, the join test, the app's strings, the plan.
