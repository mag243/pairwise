# 0052. A pair comes forward and minimizes together

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
A pair should behave as one window: bringing one forward brings the other, without taking focus from the first, and minimizing one minimizes the other (the owner's choice 3). A window can come forward in many ways: a click, Command-Tab, the Dock, Mission Control or a menu.

## Decision
- **While a pair exists, the window list is read four times a second,** without asking any app, and not during a press or a drag.
- **When the frontmost normal window is in a pair and its partner is not right behind it, the partner comes forward, and then that window again,** so that it stays on top and keeps focus. This happens once for each change of the frontmost window, so an app that refuses is not asked again and again. A window in front of the pair, of another app, leaves everything alone.
- **A window of a pair that leaves the list is asked why.**
  - Minimized: its partner is minimized as well. When one of them comes back, so does the other.
  - Gone or full screen: the pair ends, and the other window stays where it is, as before, with no sound.
  - Anything else, such as another Space or a hidden app: nothing happens, and the pair stays.

## Alternatives
- **The apps' Accessibility notifications:** immediate, but an observer per app and per window, which an app can fail to send, and many cases to keep track of.
- **Reacting to a press and to app activation only:** immediate for those, but misses a window brought forward within one app.
- **A higher rate:** a shorter delay, at a higher steady cost.

## Consequences
- Positive: one rule covers all ways a window comes forward, and a pair that ends by itself is noticed without a press.
- Negative / risks: the partner comes up to a quarter of a second later, which can show. The steady cost is about 0.5 % of a core while a pair exists, from the 1 to 2 ms of a window list. A window that was brought forward on purpose over its partner's place brings the partner too.
- Changes now: `PairwiseCore` (`PairWatch`, `MovableWindow`), the window, the model, the fake, the plan.
