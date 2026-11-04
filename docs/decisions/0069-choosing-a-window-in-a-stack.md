# 0069. Choosing a window in a stack

- **Status:** Accepted
- **Date:** 2026-11-04
- **Milestone:** M3b

## Context
With many windows over each other, the owner can hardly influence which window a dragged window joins. Three things cause this. Near an edge the closest edge wins, also of a window that lies hidden behind others. Windows that may not be joined, such as those in a pair, are left out before the rule looks at what is in front, so a window hidden behind one of them can win, against what ADR 0038 meant. And the dragged window covers what the user aims at, while the guide shows only where it lands, not which window it joins.

## Decision
- **What is visible comes first.** The window on top under the pointer is the target. When it may not be joined, there is no target there, and nothing behind it wins by itself. Near an edge, only an edge counts of which at least 20 points show past the windows in front of it, within the height of the dragged window. The dragged window itself covers nothing, as the user moves it out of the way. The closest edge wins, and at the same distance the frontmost window.
- **The target gets an amber outline** around all of it, above all other windows, next to the guide of where the dragged window lands. A hidden target shows the same way.
- **Command-` goes to the next choice,** the key to the left of 1 that macOS uses to go through an app's windows. The choices are the joinable windows under the pointer from front to back, or near an edge the visible ones and then the hidden ones, each by distance. "No window" is the first choice when nothing joinable is visible, and after the last choice it starts over. A key that repeats counts once. When the set of windows changes, as the pointer moves on, the choice starts at the first again.
- **The key is seen only while joining.** The tap for key presses is installed disabled and is on only during a joining drag. There it withholds Command-` and passes every other key. So Pairwise sees no typing at any other time, and the Accessibility permission remains enough.

## Alternatives
- **Scrolling through the windows:** natural with a wheel, but hard on a trackpad with a finger already holding the drag.
- **Tab with Command:** macOS's app switcher has that.
- **A tap for keys that is always on:** simpler, but every keystroke passes through Pairwise, which it does not need.
- **Raising the target while hovering:** shows the window itself, but changes the order of the user's windows for a drag that may end elsewhere.

## Consequences
- Positive: what you see is what joins, you see what it is, and a hidden window can still be reached on purpose.
- Negative / risks: near an edge, a window shown by only a sliver of less than 20 points joins only with Command-`. Command-` does not reach the app during a joining drag. On keyboards that give that place another character, the key keeps its place and not its character.
- Changes now: `JoinRule`, `JoinPlace`, `JoinPick`, `PointerButtonEvent`, the protocol, the tap, the mark panel, the model, the fake, the Help tab and its translations, README, the page.
