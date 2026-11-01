# 0033. Pairs as a model

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M3

## Context
So far every press on another app's window takes a picture and watches for a drag, with the first window of a chosen app as the partner. Pairwise needs real pairs, and a window outside a pair must behave as if Pairwise were not there.

## Decision
- **`PairBook` in `PairwiseCore`** holds the pairs by window number, with which window is on the left. A window is in one pair at most, and not in a pair with itself.
- **A press asks the window server only for the number of the window on top.** A number in no pair ends the matter: no call to any app, no picture, no ticks.
- **The partner can be on either side,** and the panel shows the pair in its own order.
- **A pair ends when one window has closed, is minimized or is full screen.** This is seen at the next press on either window, without watching for it. The other window stays where it is, and that drag passes. Minimizing together (step 7) changes the minimized case.
- **The choice of partner app goes,** as pairs replace it. Until joining exists (step 4), only the stress test makes pairs.

## Alternatives
- **Watching apps through `AXObserver` for closed windows:** sooner, but a lot of machinery for something only a press needs to know.
- **Keeping the partner app until step 4:** code that goes one step later.

## Consequences
- Positive: a window outside a pair costs one window list per press and nothing else. The picture on every click is gone.
- Negative / risks: a press still holds up input for the time of one window list. A window number could in theory be reused after a window closes; the check at the press finds the closed window first through its element.
- Changes now: `PairwiseCore`, the window system protocol and module, the model, the app's window and strings, the stress test.
