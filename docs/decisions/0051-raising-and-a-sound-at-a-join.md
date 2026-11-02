# 0051. Raising and a sound at a join

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
The window joined to could stay behind other windows until the pair was dragged, so a join did not show what had been joined. The owner also asked for a click at a join and at parting, which a user can turn off.

## Decision
- **At a join, both windows come forward,** the window joined to first, so that the one being dragged ends on top. With a lock, the window that was in front ends on top. Raising does not take focus from another app's window beyond what macOS does for it.
- **A join and a parting by the user make a short sound:** with Command, or with the lock. A pair that ends because a window has gone, is minimized or goes full screen makes none, as the user did not ask for it.
- **The sounds are two of the system's own,** so that nothing is added to the app, and they differ so that joining and parting can be told apart.
- **A setting turns them off.** They are on by default. It is stored by the app and given to the model at launch, as with ADR 0043.

## Alternatives
- **Own sound files:** could fit better, at the cost of making and shipping them. They can replace these later.
- **Off by default:** a user would not find out they exist. The owner asks for a way to turn them off, not for them to start off.
- **Raising only at the next drag:** what happened until now.

## Consequences
- Positive: a join shows at once what became a pair, and joining and parting can be heard.
- Negative / risks: raising can bring a window forward over something the user was looking at. System sounds follow the system's volume, and can differ per version of macOS.
- Changes now: `WindowSystemProviding`, the window system, the model, the fake, the app's settings and strings, the plan.
