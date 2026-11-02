# 0035. Joining and coming apart with Option

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
Pairs exist as a model (ADR 0033), but nothing makes them. The owner chose a key held while dragging, so that normal dragging stays normal, and the dragged window taking the other's height and top. an earlier project found it hard to tell a drag meant to join from one that is not, so nothing here guesses.

## Decision
- **The key is Option,** read at the press. Starting with Option from memory: macOS uses Option during a window drag for tiling, which may clash, and this is to be judged by hand.
- **Joining.** With Option held at the press, macOS drags the window as usual and no event is withheld. Once the window has moved, each tick looks for a normal window whose left or right edge is within 24 points of the dragged window's opposite edge, with some height in common. The closest wins, and a guide shows where the window will land. At the release the window takes the other's height and top and goes against its edge, the two become a pair, and the seam lights up briefly.
- **Coming apart.** With Option held at a press on a window in a pair, the pair ends and that window drags alone, so it can also join elsewhere.
- **Windows in a pair are no candidates,** as a window is in one pair at most (ADR 0033).
- A click with Option joins nothing, as the window has not moved.

## Alternatives
- **Reading the key during the drag as well:** it would need ticks during every press, on every window, which ADR 0033 keeps out.
- **Withholding events and moving a panel while joining:** the window is alone here, so macOS moves it best.
- **Joining on the top and bottom edges:** left out of M3.

## Consequences
- Positive: nothing joins by accident, and a window outside a pair costs nothing more unless Option is down.
- Negative / risks: the clash with macOS's own use of Option is not known yet. An app may refuse the height, which leaves an uneven pair. The stress test cannot hold a key, so joining is covered by plain tests and by hand.
- Changes now: a rule in `PairwiseCore`, the window system protocol and module, the model, the app's strings, the plan. This takes in step 5 of the plan.
