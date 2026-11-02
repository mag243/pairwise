# 0047. A reach that follows the speed

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
ADR 0045 and 0046 have a growing partner reach 40 points under the held window, to hide its lag. The owner saw this: the partner stays over or under the other window until the release, and only then jumps to the seam. It shows when the partner is the window in front, or when the held window is see-through, so being in front cannot be relied on.

## Decision
- **A growing partner reaches as far as the seam travels in three frames, at most 40 points.** This is about its lag, so it arrives near the seam instead of behind it.
- **With the seam standing still, the reach shrinks by 30 % each tick,** and below a point it is gone. It takes about a tenth of a second from the largest reach, so the partner stands at the seam before the release, and the release moves nothing.
- A shrinking partner has no reach, as in ADR 0046.

## Alternatives
- **No reach at all:** a gap of up to 20 points in the spike while growing.
- **A reach only when the held window is in front:** a see-through window still shows it, and the jump at the release stays.
- **Raising the held window at the start of a resize:** it changes which window is in front, which a resize by itself does not ask for.

## Consequences
- Positive: nothing stands over or under the other window once the hand stops, and the release moves nothing.
- Negative / risks: each change of the reach is a call to the app while the seam stands still, for about a tenth of a second. A partner in front can still show the reach during a fast drag, for as long as it moves.
- Changes now: `SeamFollow`, the model.
