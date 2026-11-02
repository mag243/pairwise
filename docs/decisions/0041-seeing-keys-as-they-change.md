# 0041. Seeing keys as they change

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
ADR 0039 and 0040 read Command and Shift from each drag event. A key let go while the pointer stands still sends no drag event, and a release event was not read for keys. The owner let go of Shift before the release, and the window still took the other's height.

## Decision
- The tap also listens to changes of the modifier keys, and hands them to the model as an event of their own. Such an event always passes: the tap only reads it.
- While a window is joining, the change counts at once: the next tick updates the guide, and a release joins by the keys as they are at that moment.
- While the panel is up, Command coming down parts the pair on the next tick, without the pointer having to move.
- In other states the change is not used, as the next drag event carries the same keys.

## Alternatives
- **Reading the keys from the release event only:** the outcome would be right, but the guide would go on showing the old place until the release.
- **Asking the system for the keys on each tick:** its state lags behind the events (ADR 0036).

## Consequences
- Positive: the guide and the outcome always follow the keys.
- Negative / risks: the tap sees every change of a modifier key in every app, also outside a drag. It reads only which keys are down, and handling one costs a single state check.
- Changes now: `PointerButtonEvent`, the tap, the model, their tests.
