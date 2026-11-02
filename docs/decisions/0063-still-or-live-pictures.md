# 0063. Still or live pictures

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3a

## Context
ADR 0049 shows live frames during a drag. macOS then shows its purple recording icon at every drag, which people can find suspicious in an app they do not know yet, however well it is explained. Tried by hand: with one still picture per drag the icon stays away, both for a pair and at a seam. In return video stands still, and the seam shows stretching, as ADR 0048 found.

## Decision
A setting, Pictures while dragging, with two values and one rule: **Still** is one picture per window at the start of a drag, with no icon. **Live** is live frames, with the icon, for a pair and at a seam alike. Still is the default.

The settings say what each costs, and the Screen Recording permission stays needed for both. The debug setting with several frame rates stays for testing, and test runs use Live, whatever the user chose.

## Alternatives
- **Still for a pair and live at a seam:** the best picture and few icons, but harder to explain than one rule, and the icon would still surprise at the seam.
- **Only live, with an explanation:** sharp, but the icon at every drag.
- **Repeated still pictures during a drag:** could look nearly live and might escape the icon. That is recording without what the icon is there to show, so this is not done.
- **Live as the default:** the best first look at the seam, but a new app showing a recording icon at every drag costs more trust than a stretched seam.

## Consequences
- Positive: by default no recording icon, and a clear choice for whoever wants live.
- Negative / risks: by default the seam looks less good during a drag, and video stands still. To be looked at: whether the stretching can be less.
- Changes now: `DragPictures` in Core with tests, the setting with nl and de strings, the page and the README.
