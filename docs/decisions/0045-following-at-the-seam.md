# 0045. Following at the seam

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
Resizing a window of a pair at its seam has to resize the other, so that the seam stays shared. A moving window lagged too much to follow through the Accessibility API (ADR 0024), and pictures do not help while content changes size. The spike in `docs/reference/spike-following.md` measured a gap of 2 to 7 points on average, and 20 at most, on Finder windows.

## Decision
- **macOS keeps resizing the window, and its drag events pass.** The partner follows on each tick, from the window server's place.
- **While resizing, the partner reaches under the window being held,** by a fixed 40 points. A pressed window is in front, so a lagging partner shows no gap. At the release both go exactly against each other.
- **A partner's far edge stays where it was at the press.** Reading it back during the drag would add up rounding and lag.
- **Only the seam's edge counts.** Resizing at an outer edge, or at the top or bottom, changes one window only.
- **Minimum sizes:** a held window that stops is one macOS has stopped, and the partner stops with it. A partner that refuses to go narrower is seen at the release, and the held window comes back to meet it.
- Everything that calls an app happens on ticks, the release included.

## Alternatives
- **The app's resize notifications:** they ask more of each app, and the window server tells the same on every frame.
- **Taking over the drag, as with moving:** stretched pictures would show wrong content, and it would have to redo macOS's own rules for a resize.
- **No reach under the window:** a gap with whatever lies behind it, up to 20 points in the spike and more by hand.
- **Stopping the held window at the partner's minimum during the drag:** it would fight macOS's drag on every frame.

## Consequences
- Positive: a resize feels like macOS's own in the held window, whatever the partner does.
- Negative / risks: the partner's content is 40 points narrower in view while resizing, and a very fast hand can still outrun that. A slow app lags. The held window can go over a partner at its minimum until the release. Whether this looks good is for the owner's eye.
- Changes now: `PairwiseCore` (`SeamFollow`), the model, the plan.
