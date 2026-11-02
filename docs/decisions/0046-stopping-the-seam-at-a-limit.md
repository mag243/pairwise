# 0046. Stopping the seam at a window's limit

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
With ADR 0045, a partner at its minimum or maximum width did not stop the seam during the drag: the held window went over it, or a gap opened, and everything jumped back at the release. The owner finds that this would disturb, and wants the drag to stop as soon as a window will go no further. An app's limits are not known in advance, as far as is known: the join test lists a real window's attributes to check this.

## Decision
- **Pairwise learns a limit from the partner's answer.** After each follow it reads the width the partner ended up with. The same width three follows in a row, more than 24 points from what was asked, is a limit. A lagging app changes its width as it catches up, and an app that rounds stays within the 24 points.
- **Past a limit, the drag events are withheld,** so that macOS does not resize further. The tap decides from the pointer alone, without calling any app: the seam's place at the press plus the distance the pointer has gone. When the pointer comes back, the events pass again, and the drag goes on.
- **A held window that went past the limit before it was learned comes back to it** on the next tick, while the events are withheld.
- **A partner that grows reaches under the held window** (ADR 0045), and a partner that shrinks does not. A shrinking partner's lag is hidden behind the held window anyway, and asking for its exact width shows its minimum at the exact place.
- The limit counts for this drag. The release works as in ADR 0045, as the last correction.

This changes ADR 0045's consequence that a partner at its limit does not stop the seam, and its fixed reach. The rest of it stands.

## Alternatives
- **Trying sizes at the press to find the limits:** the partner would visibly change at each press.
- **Taking over the whole drag and resizing the held window through its app:** every resize would lag, where macOS's own does not.
- **Remembering a limit between drags:** saves a few frames of overshoot, while a window's limit can change with its content. It can still come.

## Consequences
- Positive: the seam stops where a window will go no further, and comes along again when the pointer returns.
- Negative / risks: the held window overshoots for a few frames the first time, and then comes back. An app can ignore a resize during its own resize tracking, and then the correction waits for the release. An app that answers late and stays the same for three frames looks like a limit for the rest of that drag.
- Changes now: `PairwiseCore` (`SeamLimits`, `SeamFollow`), the model, the fake, the join test.
