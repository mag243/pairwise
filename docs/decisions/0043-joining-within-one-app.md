# 0043. Joining within one app

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
The owner wants to choose between joining any window and joining only a window of the same app, as with windows close together the wrong one can be picked up.

## Decision
- A setting says what Command joins with: any window, the default, or windows of the same app.
- Adding Control during the drag gives the other choice, as long as it is down. The guide follows at once.
- Control counts during the drag only. Held at the press it makes a right click, which macOS and the app handle as ever. By hand, Control during a drag did not clash.
- Two windows are of the same app when one process owns them, which the window server tells without asking the app.
- The setting is stored by the app and given to the model at launch, so that the model and its tests need no global state.

## Alternatives
- **Shift with Command for the same app:** Shift means equal height (ADR 0040).
- **Only a setting, or only a key:** the key alone gives no way to make the same app the usual case, and the setting alone makes the other choice a trip to the settings.
- **Comparing bundle identifiers:** the same answer for nearly all apps, at the cost of a lookup.

## Consequences
- Positive: windows of other apps stay out of the way when asked, and the choice costs no extra call.
- Negative / risks: an app that runs several processes, as some browsers can, counts as several apps.
- Changes now: `PairwiseCore` (`JoinScope`, `ScreenWindow`, `JoinRule`), `PointerButtonEvent`, the tap, the model, the fake, the app's settings and strings.
