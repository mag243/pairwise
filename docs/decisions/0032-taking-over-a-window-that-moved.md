# 0032. Taking over once the window has moved

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M3

## Context
ADR 0024 holds back every drag that starts in a fixed band of 52 points, so a drag on a tab or other control there does nothing. The M3 plan proposed a table of Accessibility roles to tell a title bar from a control. Such a table is a guess per app, and web content and custom title bars would keep breaking it. macOS already knows what is a window drag: it moves the window. ADR 0013 used this rule before.

## Decision
- A press passes, and so do its drag events, so macOS and the app handle them as they would without Pairwise. The picture is started at the press.
- On each tick Pairwise compares the window's place from the window server with its place at the press. When the origin has changed and the size has not, this is a window drag. From then on the drag events are withheld, and the panel takes over where the pointer took the window, reckoned from the press: at that moment the window itself lags a little behind the pointer.
- When the size has changed, this is a resize, and the rest of the press passes.
- When the release comes before the panel, a window that has moved keeps its place and the partner goes beside it.
- The fixed band and the role table are not used. This replaces step 2 of the M3 plan.

## Alternatives
- **A table of roles (the plan):** a guess per app, and a wrong guess blocks a drag or moves one window.
- **The band with a table:** keeps both problems.

## Consequences
- Positive: tabs, text selection, sliders and custom title bars work in every app, and no app needs special handling.
- Negative / risks: the window moves by itself for a frame or two before the panel appears, and snapping can act in that moment. It rests on macOS stopping a drag when its events stop arriving midway, which the stress test measures; ADR 0023 only tried this from the start of a drag. A tick reads the window list during every press, which step 3 limits to windows in a pair.
- Changes now: `DragHoldRule`, `PairDragModel`, the plan.
