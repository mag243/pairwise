# 0042. A lock on the seam

- **Status:** Superseded by 0044
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
Parting with Command needs a drag, and people tend to press the key first, which opens macOS's folder menu on a title (ADR 0039). A key cannot be discovered either, while M3 asks that windows come apart without a manual. The owner chose a lock on the seam, to click.

## Decision
- **A small closed lock shows in the middle of a seam while the pointer is near that seam.** It goes away once the pointer has left, a little further out than where it came, so that it does not flicker at the border.
- **It never lies over another window:** it shows only when the pair is on top both at the pointer and at the lock's place. It does not show during a press or a drag, and it needs both windows on screen and side by side.
- **A click on it ends the pair.** Both windows stay where they are, the lock shows open for a moment, and focus stays where it was.
- **The tap handles the click, and the lock takes no mouse events.** A press on the lock's place would otherwise reach both the lock and the logic for the window below. The lock is Pairwise's own, so withholding its press, drags and release does not touch an event Pairwise does not own. A release away from the lock cancels, as with any button.
- **While a pair exists, the pointer is looked at ten times a second, without asking any app.** The window list is read only when the pointer has moved or the lock shows. Without a pair nothing runs.
- Command during a drag stays as the quick way to part.

## Alternatives
- **A lock that is always visible:** shows the pair's state at a glance, but lies over content and over windows in front.
- **A panel that takes the click itself:** simple in AppKit, but it needs the tap to stay out of the way all the same, and a click can bring focus along.
- **Watching pointer moves with a monitor or the tap:** a call for every move, whose number depends on the mouse, and a last move dropped by any limit would leave the lock unseen. A fixed rate costs the same whatever the mouse does, at the price of the lock coming up to a tenth of a second late.
- **Hiding Command from a press on a title:** still possible, and it would help joining as well, but it changes other apps' events.

## Consequences
- Positive: parting is visible and needs no key and no drag, and a pair shows that it is one.
- Negative / risks: a small steady cost while a pair exists. The lock lies on the seam that step 6 will drag, so it takes up a small part of it. The lock does not know about Pairwise's own settings window.
- Changes now: `PairwiseCore` (the seam and the rule for the lock), the window system, the model, the fake, the join test, the app's strings, the plan.
