# 0030. Moving a window without its animation

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M2

## Context
A YouTube video in Safari stays live during a drag (ADR 0029). At the release, though, the owner sees the Safari window fly in from the bottom right corner, where it was parked. From memory, not checked against Apple's documentation: an app with the attribute `AXEnhancedUserInterface` on animates moves made through the Accessibility API, and other window managers turn it off around a move.

## Decision
A move through the Accessibility API turns `AXEnhancedUserInterface` off on the window's app if it is on, moves the window, and turns it back on. The attribute is put back whatever the move's outcome, as other tools may rely on it.

## Alternatives
- **Keeping the panel up until the window has arrived:** the window would still fly across the screen, above other windows.
- **Parking closer to the window's place:** a shorter flight, and the window would stick out from behind the panel while parked.

## Consequences
- Positive: the window should land at once. To be confirmed by hand with Safari, as no test here has an app that animates.
- Negative / risks: each move costs up to three more calls to the app, and it happens only at the start and end of a drag. If the fly-in has another cause, this does not help.
- Changes now: `AccessibilityWindow`.
