# 0020. Comparing the stand-in with the real window

- **Status:** Superseded by 0028
- **Date:** 2026-11-01
- **Milestone:** M2

## Context
The owner questions what the stand-in gives: it knows the dragged window's place as late as a real partner would. It only removes the other app from carrying out a move. Its costs are the Screen Recording permission, a still picture, parking the partner, and more code. M1 judged the real partner while it followed the pointer, before ADR 0018 and 0019, so the two have not been compared fairly.

## Decision
- The app's window gets a switch to use the picture or not, so the two can be dragged straight after each other.
- A partner moving as itself also looks ahead with the pointer's movement (this changes ADR 0019), with its own value, since its app adds a delay of its own. It starts at 16 ms; the stand-in stays at 8 ms.
- The owner judges by eye. If the real window is nearly as good, the stand-in goes, subject to a check with a slower app than Finder. If the stand-in is clearly better, display-synchronised prediction is next.

**Outcome:** with Finder as the partner the difference is very small, with the picture perhaps a little smoother. The owner chose the stand-in, without the check with a slower app.

## Alternatives
- **Revoking Screen Recording to compare:** needs a restart between each drag, and the real window would not look ahead.
- **Building the prediction first:** more work, and wasted if the stand-in goes.

## Consequences
- Positive: the choice rests on a like-for-like comparison.
- Negative / risks: Finder may answer faster than other apps, so a good result for the real window needs that check. Both settings are for the spike.
- For the check with a slower app, the app's window chooses which running app gives the partner (this changes the simple partner of ADR 0013). Finder stays the first choice.
- Changes now: `FollowModel`, the window system protocol, the app's window and its strings.
