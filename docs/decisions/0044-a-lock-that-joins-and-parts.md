# 0044. A lock that joins and parts

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
ADR 0042 put a closed lock on the seam of a pair. The owner wants the same for two windows that stand against each other without being a pair, whether pushed together or just parted: an open lock, to click to join them. This also gives a way to join that needs no key.

## Decision
- **A lock shows in the middle of a seam while the pointer is near it:** closed on a pair, open on two windows side by side that are in no pair. It goes away once the pointer has left, a little further out than where it came. Between two windows no further apart than 4 points. An open lock follows the setting of which windows can join (ADR 0043).
- **It never lies over another window:** it shows only when the two are on top both at the pointer and at the lock's place. It does not show during a press or a drag, or on a seam shorter than the lock.
- **A click changes its state.** A closed lock ends the pair, and both windows stay where they are. An open lock joins them, and as a pair's tops are level (ADR 0040), the window further back takes the top of the one in front and closes any gap. Neither changes size, and focus stays where it was.
- **The tap handles the click, and the lock takes no mouse events.** A press on the lock's place would otherwise reach both the lock and the logic for the window below. The lock is Pairwise's own, so withholding its press, drags and release does not touch an event Pairwise does not own. A release away from the lock cancels, as with any button.
- **This limits "a window not in a pair behaves as without Pairwise":** a drag starting on the lock's own small place, such as to resize, does nothing. The owner accepted this, and M3's acceptance criterion says so.
- **While Pairwise runs, the pointer is looked at ten times a second, without asking any app.** The window list is read only when the pointer has moved or a lock shows. The owner's log has a press on a free window, mostly that list, at 1 to 2 ms, so at most 1 to 2 % of one core while the pointer moves.
- Moving a window calls its app, so joining happens on the next tick and not on the release event, which would hold up all input.
- Command during a drag stays as the quick way to join and part.

## Alternatives
- **Only for windows that were parted:** cheaper to watch for, but it leaves out windows pushed together, and the state would have to be remembered.
- **Keeping windows where they are at a join:** the first drag would make one jump to level the tops.
- **A lock that is always visible:** shows the state at a glance, but lies over content and over windows in front.
- **A panel that takes the click itself:** simple in AppKit, but it needs the tap to stay out of the way all the same, and a click can bring focus along.
- **Watching pointer moves with a monitor or the tap:** a call for every move, whose number depends on the mouse, and a last move dropped by any limit would leave the lock unseen. A fixed rate costs the same whatever the mouse does, at the price of the lock coming up to a tenth of a second late.
- **Hiding Command from a press on a title:** it changes other apps' events.

## Consequences
- Positive: joining and parting are visible and need no key and no drag, and a seam shows the state of its windows.
- Negative / risks: a small steady cost while Pairwise runs. With many windows tiled against each other, locks come up more often, and a setting to turn the open lock off can follow. The lock lies on the seam that step 6 will drag, and it does not know about Pairwise's own settings window.
- Changes now: `PairwiseCore`, the window system, the model, the fake, the join test, the app's strings, the plan.
