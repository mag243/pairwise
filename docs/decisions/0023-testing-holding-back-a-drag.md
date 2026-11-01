# 0023. Testing whether a window drag can be held back

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M2

## Context
The owner asked for a pair that macOS moves as one. macOS offers that only within one app. The way around it: during a drag, Pairwise shows both windows as pictures in one window of its own and moves that itself, so the two cannot drift apart. This needs the system to stop dragging the real window, which a listen-only tap cannot do. It is not known whether withholding the drag events from an event tap stops a window drag at all. The rest of the idea depends on that, so it is tried first, on its own.

## Decision
- A separate test in the app's window, started by hand and not running together with following. It uses an active event tap on the left mouse button.
- The tap withholds only drag events that follow a press in the top band of another app's window, 52 points high. Presses and releases always pass, so clicks and title bar buttons keep working, and so does dragging within a window's content. This is the only input it owns (the hard rule on event taps).
- It fails open. After 5 seconds of one drag the events pass again, an unknown window means everything passes, the tap lives only while the test runs, and the system turns off an active tap that is too slow.
- The report per drag says how far the pointer and the window moved, and how many events were held back. A window that stays put while the pointer travels means the idea can go on.

## Alternatives
- **Building the one-window drag first:** much work resting on an untried assumption.
- **Withholding the press as well:** would block clicks until a drag is told from a click. Kept for if withholding drags alone is not enough.
- **Asking the owner to judge by eye only:** the numbers are exact, and the eye is still needed for clicks.

## Consequences
- Positive: a cheap answer to the question the idea rests on.
- Negative / risks: while the test runs, title bars cannot be dragged, and a tap on the main thread may delay input for as long as a call to a slow app takes at the press, up to the messaging timeout. A fixed band height does not fit every window; it is enough for a test.
- This does not decide the one-window drag. That gets its own ADR if the test succeeds.
- Changes now: a pure rule in `PairwiseCore`, the window system protocol, a tap, a test model, the app's window and its strings.
