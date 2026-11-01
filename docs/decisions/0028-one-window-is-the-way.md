# 0028. One window while dragging is the way; the rest goes

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M2

## Context
The owner judged the one-window drag of ADR 0024: smooth, with the flash at the release gone and the real windows out of sight. The stress test (ADR 0027) moved both windows 40 times out of 40. The earlier ways of following keep a visible effect and a lot of code and settings.

## Decision
- Moving as one window is what Pairwise does while dragging. Following a real window or a picture beside the dragged window goes, with what served only those: the listen-only tap, the grip, the look-ahead, reading the window server's place on each tick, and the switches and settings for comparing.
- Without the Screen Recording permission nothing is taken over: macOS drags the one window as usual, and the app says why. This needs no second way of following.
- The picture of a window, parking, placing at the release, the display ticks, the choice of partner app and the stress test stay.

## Alternatives
- **Keeping the partner following as itself without the permission:** a pair that moves together of a sort, for the price of keeping that code, and it lags visibly.
- **Keeping the old ways behind a switch:** code nobody runs. Git keeps it.

## Consequences
- Positive: one way of dragging, and far less code and fewer settings.
- Negative / risks: Screen Recording is now needed for a pair to move at all. The limits of ADR 0024 stay for M3: a drag on a tab or other control in the fixed band does nothing, snapping and tiling are lost during such a drag, and a crash during a drag leaves two windows parked. Live content in the pictures, at a chosen frame rate, is still to come.
- `PairwiseWindowSystem` stands at about 7 % line coverage against its target of 75 %, as its code needs permissions and real windows, so `tools/build.sh coverage` stays red for it. The target stands, and M3 meets it with a seam around the system calls; the stress test covers this code by hand until then.
- Superseded by this: ADR 0013, 0015, 0016, 0018, 0019, 0020 and 0022, and of ADR 0014 the stand-in beside a window that macOS drags. ADR 0021 was already superseded.
- Changes now: `PairwiseCore`, `PairwiseWindowSystem`, `PairwiseUI`, the app's window, its strings, the plans.
