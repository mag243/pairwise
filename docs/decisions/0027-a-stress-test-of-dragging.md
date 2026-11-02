# 0027. A stress test of dragging, run by the agent

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M2

## Context
The partner sometimes does not go along. It happens one time in a number of tries, and each round has cost the owner a series of drags by hand. Whether a drag was taken over can be measured from the windows' places, so a person need not watch.

## Decision
`tools/build.sh run --drag-stress-test <file>` makes the app test itself and quit. It opens two Finder windows on empty temporary folders of its own, and pins them as the dragged window and the partner, so no other window can move. It posts real mouse events through the system, varying the place on the title bar and the waits before and after the press, and reads from the window server where both windows ended up. Each try is written to the file as both moved, only the held window moved, or nothing moved, with what became of the press. At the end it closes its windows, puts the pointer back and quits.

`tools/build.sh run --join-test <file>` does the same for joining and parting (ADR 0035). It posts the join key as a key press, may join only its own two windows, writes where the guide stood, and saves a picture of that part of the screen beside the file. Posted keys are not a finger on the key either.

A press lands on whatever is on top, and in Finder a drag from a file list copies files: a run that lost track of its windows left a dialog asking to copy 3 items. So the test presses only when its own window is on top at that place, and otherwise skips the drag.

It takes over the pointer for as long as it runs, so it runs only when the owner has asked for it (as ADR 0011 for UI tests).

## Alternatives
- **An XCUITest:** an earlier project found that its drags did not move windows.
- **A script outside the app:** it would need the permission for the terminal, which the owner keeps off.
- **More logging, by hand:** the rounds this replaces.

## Consequences
- Positive: the agent can reproduce the fault and count it, without the owner.
- Negative / risks: it drags Finder windows only, so a fault of another app stays for by hand. Posted events are not a hand on a trackpad. It is not a plain test: it waits on real time and needs permissions, so it is not part of `tools/build.sh`'s gates.
- Changes now: `PairwiseWindowSystem`, `PairDragModel`, the app's start.
