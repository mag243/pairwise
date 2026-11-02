# 0064. Placeholders by default

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3a

## Context
ADR 0063 made one still picture the default, with no recording icon. That still takes the Screen Recording permission, which is a lot to ask of a new user for a window manager, and it stretches at a seam. On trial, an empty plane with the app's icon and the window's title proved good enough by hand, as smooth as a still picture, and it stretches nothing. The owner chose it as the default.

## Decision
A third choice in Pictures while dragging, **Placeholder**, and the default: an empty plane that follows light or dark mode, with the app's icon in its middle, and a title bar with a window's three buttons and its title, read through the Accessibility API. Nothing is captured, and the capture API is not called for anything.

- Pairwise needs Accessibility alone: it starts without Screen Recording, and the settings window opens by itself only for Accessibility.
- Still and Live stay, and need Screen Recording. Choosing one asks for it. Until it is given, or when it is taken away, Pairwise uses placeholders and says so in the settings. It does not stop.
- At a seam a placeholder is layers that only change place, as drawing it anew at every move was visibly slow.

## Alternatives
- **Still as the default (ADR 0063):** a nicer first look during a drag, but a permission for it, and stretching at a seam.
- **Moving the real windows:** needs no capture at all, but the partner lags visibly (M1), which is what Pairwise is there to avoid.
- **Only an outline of each window:** lighter still, but it says less about which window is which.

## Consequences
- Positive: "Pairwise records nothing by default", one permission on a first start, no purple icon and no stretching.
- Negative / risks: a first drag looks less like the real windows, and the content comes back only at the release. People must discover Still and Live in the settings.
- Changes now: `DragPictures`, the model's rules for the permissions, the settings, the first start, the page, the README, the translations. ADR 0063 is superseded in its default only.
