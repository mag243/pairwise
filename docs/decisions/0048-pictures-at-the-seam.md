# 0048. Pictures at the seam

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
With ADR 0045 and 0046 the seam went through two apps: macOS resized one window, and the other followed through its app. That left a choice between a gap, a reach over or under the other window with a jump at the release, and a window that jumped during the drag (ADR 0047). The owner proposed what ADR 0024 does for moving: pictures, with the real windows resizing out of sight. Live pictures are a later step, to be measured. This decision is the step before it, and may turn out to be enough.

## Decision
- **As soon as a seam moves, the panel with the pair's pictures shows, still, and the drag events are withheld.** The panel draws the seam at the pointer, without asking any app. If the pictures come later, the events wait for them, as with moving, up to the same limit.
- **The real windows stay where they are, under the panel,** as the far edges do not move and the panel covers both. Nothing is parked.
- **Each picture is cut off at the seam when its window narrows.** When it widens, a thin column near the seam is stretched over the extra room, as that is mostly plain window, and the rest of the picture stays sharp.
- **Ten times a second both windows get the seam's place, under the panel.** A limit shows as a width other than asked (ADR 0046), and the seam stops there. This keeps the windows close to where they end, and costs two calls to apps per look.
- **At the release both windows go exactly to the seam, on the next tick,** and the panel comes down after the settle time, as with moving. A window with another width than asked keeps its far edge, and the other window meets it.
- **A limit needs two answers in a row** rather than three, as the answers are further apart in time.
- **Without pictures, the events pass:** macOS resizes the one window, and at the release the other goes beside it.
- This replaces following with a reach. The rule of which window counts as held, and that only the seam's edge counts, stand (ADR 0045).

## Alternatives
- **Asking for extreme sizes under the panel to find the limits at once:** exact and without an overshoot, but every press would make apps lay out at their smallest. A terminal running a full-screen program would redraw at a tiny width.
- **Stretching the whole picture:** simplest, but all text squeezes along.
- **Only the partner as a picture:** one stream later on, but two kinds of picture side by side, and the limits stay a fight with macOS.
- **Live pictures at once:** the most unknowns: what a frame of another width should look like, and a stream's fixed size. This step is needed for it anyway.

## Consequences
- Positive: the seam stands exactly under the pointer, with no gap and no overlap, whichever apps these are.
- Negative / risks: the content changes only at the release. A limit is found up to about a fifth of a second late, and then the seam comes back to it. The calls to the apps run on the main thread, which may show as small hitches. An app that answers late can look like a limit for the rest of that drag. A window that rounds its width can leave a small gap with a held window that rounds as well.
- Changes now: `WindowStandIn`, `StandInPanel`, `SeamFollow`, `SeamLimits`, the model, the fake.
