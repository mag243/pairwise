# 0069. Joining by the edge that moves

- **Status:** Accepted
- **Date:** 2026-11-04
- **Milestone:** M3b

## Context
With many windows over each other, the owner can hardly influence which window a dragged window joins, and agreed on a new rule with the agent before any code changed. The rule of ADR 0038 goes wrong in four ways. A window that overlaps another gets a proposal as soon as the drag starts, as the pointer is already over the other. A drag to the right can propose a window on the left, as neither the closest edge nor the half under the pointer looks at the direction. A hidden window can win, by its edge or behind a window in a pair. And the dragged window covers what the user aims at, while the guide shows only where it lands, not which window it joins.

What a user means shows in the movement towards an edge, not in an overlap.

## Decision
- **Direction first.** The direction is the last horizontal movement of the pointer of at least 12 points, measured from the furthest point in the current direction, from the press on. It stays while the pointer stands still. Without a direction there is no proposal.
- **The edge that moves joins.** Moving left, the dragged window's left edge joins another's right edge. Moving right, its right edge joins another's left edge. The pointer no longer picks the window, which replaces ADR 0038.
- **When an edge counts.** The other edge lies at most 24 points ahead of the moving edge, or at most 48 points past it, so that a fast drag does not shoot through. The windows overlap vertically. Dropping a window in the middle of another joins nothing.
- **Order of the choices.** Edges that show come first: at least 20 points of the edge show past the windows in front of it, within the dragged window's height. Then the hidden ones. Within each: first a window whose height holds the pointer, then the smallest distance, then the frontmost. Windows that may not be joined join nothing, but do hide what is behind them. The dragged window hides nothing, as the user moves it. When only hidden edges count, "no window" is the first choice, so a hidden window never wins by itself.
- **The target gets an amber outline** around all of it, above all other windows, next to the guide of where the dragged window lands. A hidden target shows the same way.
- **Going through the choices:** the scroll wheel and Command-Z, for a trackpad, where scrolling during a drag is awkward. Z lies next to Command and Control, for a hand that stays on the keyboard; it goes by the key's place, so also on a QWERTZ keyboard. Scrolling down goes to the next choice and up to the previous; a wheel's event is one step, and a trackpad's movement counts per 40 points. A key that repeats counts once. A window that was chosen stays chosen while it is a choice; otherwise the first choice applies again.
- **Pairwise sees this input only while joining.** A second tap, for key presses and scrolling, is installed disabled and is on only during a joining drag. With Command down it withholds scrolling and Command-Z; every other key passes. So Pairwise sees no typing or scrolling at any other time, and the Accessibility permission remains enough.

## Alternatives
- **The pointer picks the window, with the direction for the side:** still proposes at once on an overlap.
- **Keeping joining by dropping on a window:** the owner chose not to: that is what gives the quick wrong proposals.
- **Dimming the other windows, or raising the target:** busier, or it changes the order of the user's windows for a drag that may end elsewhere.
- **Command-` to go through the choices:** out of reach of a hand on Command. Option tiles windows (ADR 0036), and Command-Space is Spotlight's.

## Consequences
- Positive: what happens follows from the movement, there is no proposal behind the window's back, you see which window it is, and a hidden window can still be reached on purpose.
- Negative / risks: this is close to ADR 0035, whose narrow band a drag could pass through (ADR 0037); the 48 points are to be judged by hand. To land on a window's far side, the user goes past that edge and moves back. Whether scrolling works during a drag on a trackpad differs per way of dragging. Pressing Command with the window already at an edge works, as the direction counts from the press.
- Changes now: `JoinRule`, `JoinPlace`, `JoinPick`, `DragHeading`, `JoinScroll`, `PointerButtonEvent`, the protocol, the tap, an outline panel, the model, the fake, the Help tab and its translations, README, the page. Supersedes ADR 0038.
