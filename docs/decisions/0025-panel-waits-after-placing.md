# 0025. The panel waits a moment after placing

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M2

## Context
The owner sees a small flash at the release (ADR 0024). The panel comes down as soon as the Accessibility calls return, and an app draws its window at the new place only after that. The owner also reports that dragging straight after pressing at a new place on the title bar sometimes moves only the held window, which means the drag was not taken over. The log says nothing about presses that are not taken over.

## Decision
- After both windows are placed, the panel stays for another 50 ms, then comes down. A new press or a stop brings it down at once.
- The log says, for each press on another app's window, whether it was taken over or why not, and how long deciding took, since the tap holds up all input meanwhile. It also says when an event passes during a drag and when the system turned the tap off.

## Alternatives
- **Waiting until the apps report the new place:** an app reports before it has drawn, so this does not tell either.
- **A fade instead of a wait:** hides a late window less well, and takes longer.

## Consequences
- Positive: the windows have had time to draw before the picture goes. The log can show the cause of a drag that was not taken over.
- Negative / risks: 50 ms is a first guess, and a slow app may need longer. During that time the panel floats above other windows.
- Changes now: `PairDragModel`, `PairDrag`, `HoldingTap`.
