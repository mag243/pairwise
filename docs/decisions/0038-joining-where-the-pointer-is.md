# 0038. Joining the window under the pointer

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
ADR 0037 joins on any overlap, with the closest edge deciding. The owner found that a Terminal window much larger than its target does not join it. A large window overlaps many others at once, also ones hidden behind others, so the closest edge can belong to any of them.

## Decision
- The pointer decides first: the target is the frontmost other window under the pointer, on the side of the half the pointer is in. The size of the dragged window plays no part.
- Otherwise, a window joins one whose opposite edge is within 24 points of its own, as in ADR 0035.
- This replaces joining on overlap from ADR 0037, which is superseded.

## Alternatives
- **Limiting the overlap rule to visible windows:** still guesses among several with a large window.
- **The window's centre instead of the pointer's place:** a large window's centre can be far from where the user looks.

## Consequences
- Positive: what is under the pointer is what joins, at any window size, and a hidden window cannot win over a visible one there.
- Negative / risks: a large window joining on the left of a small one can end partly off the screen, as it keeps its width. To be judged by hand.
- Changes now: `JoinRule`, the model, its tests.
