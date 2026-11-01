# 0026. The window under the pointer comes from the window server

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M2

## Context
The owner sees that a drag sometimes moves only the held window. The log (ADR 0025) shows why: in one run 11 presses gave "no window under the pointer", decided within about a millisecond and in clusters. Those drags are not taken over, so macOS moves the one window. The window comes from an Accessibility hit test, followed by the hit element's window attribute. Either step can give nothing, and the log does not say which. It also counts a hit on Pairwise's own windows as no window.

## Decision
The window under a point is the frontmost window at the normal level in the window server's list whose bounds hold that point, so the answer does not depend on which element is under the pointer or on what an app answers about it. Higher levels are looked through, as they hold windows that cannot be seen and cover the whole screen. If that frontmost window is Pairwise's own, there is no window to take over. The Accessibility window is then found among its app's windows by its size and closest origin (`WindowMatch`), and it keeps the window number, so it need not be looked up again.

The log also says when a release comes before the pictures, to tell clicks from drags among presses that show no pictures.

## Alternatives
- **Trying the hit test again on failure:** the answer came fast and empty, so nothing suggests a second try differs.
- **Splitting the log first to find which step failed:** another round by hand, for a cause this removes either way.

## Consequences
- Positive: the answer no longer depends on the hit element.
- Negative / risks: not yet confirmed by hand. A press costs a window list in the event tap, which holds up input for that time, and windows of an always-on-top level are not taken over. A press on a menu or the Dock above a title bar counts as a press on that title bar, which withholds only a drag that follows. If an app's windows cannot be matched, the drag still passes.
- Changes now: `AccessibilityWindowSystem`, `AccessibilityWindow`, `WindowServer`, a small rule in `PairwiseCore`.
