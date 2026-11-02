# 0039. The join key during the drag

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
Command held at the press has a meaning of its own: on a window's title, macOS opens a menu of the folders above the document. The owner got that menu from Terminal when holding Command first. So joining cannot rest on the key being down at the press.

## Decision
- Command counts at any moment during a drag, not only at the press. Every drag event says whether the key is down, so this needs no ticks on windows outside a pair: a press only notes the number of the window under the pointer.
- When a drag event carries the key on a window not in a pair, joining starts. Letting go of the key before the release takes the guide away and joins nothing.
- Command at the press still works, away from a title.
- Parting stays at the press: on a window in a pair, the panel takes over as soon as the window moves, and nothing can be parted from the panel.

## Alternatives
- **Another key:** Option tiles the window (ADR 0036), Control is a right click, and Shift is not known to be free. The moment is the problem here, not the key.
- **Only during the drag, and not at the press:** would take away a way that works elsewhere on a window.

## Consequences
- Positive: dragging starts as any drag does, and the key is pressed once the intent is there.
- Negative / risks: to part a window whose title takes up the whole title bar, Command at the press opens that menu; the part of a title bar beside the title does not. Parting may want another way, for which the owner's experience decides.
- Changes now: `PointerButtonEvent`, the tap, the model, the fake, the app's strings.
