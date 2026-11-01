# 0021. Predicting the stand-in, in step with the display

- **Status:** Superseded by 0022
- **Date:** 2026-11-01
- **Milestone:** M2

## Context
The owner chose the stand-in (ADR 0020), and looking ahead (ADR 0019) leaves a visible effect. The stand-in jumps to a newly worked out place on each tick. The timer is not in step with the display, and the window server's place changes unevenly. The owner's idea: extrapolate the window's movement, using that the pointer moves first, and animate the stand-in smoothly to the predicted place at the predicted speed. Only a stand-in can do this, as a real window moves when its app gets to it.

## Decision
- **Ticks come from a display link** on the main display, so reading the place and moving the stand-in happen once per frame. A timer is the fallback when there is no display link. A window dragged to a display with another refresh rate keeps the main display's rate.
- **`MotionPrediction`, a pure rule in `PairwiseCore`,** holds a place and a speed. The speed is the pointer's, smoothed. On each frame the place moves on by that speed, and is then pulled part of the way to where the window will be: the window server's place plus the speed times the look-ahead. It stays within a fixed distance of that spot, so a window that hangs cannot be left far behind. When the pointer rests, the speed goes to zero and the place settles exactly on the window's.
- **For comparing,** the app's window has a switch for this. Off, the stand-in looks ahead as in ADR 0019. The look-ahead setting serves both, and the release still places the partner from the real frame.

## Alternatives
- **A Kalman filter:** more to tune, and no reason yet to expect better than this.
- **Predicting from the window's own movement only:** reacts later than the pointer, which is the reason for the idea.
- **AppKit's window animation:** runs towards a fixed end over a fixed time, and cannot follow a target that changes every frame.

## Consequences
- Positive: an even movement in step with the display, which should remove jumps from uneven updates.
- Negative / risks: a sudden start, stop or turn is where a prediction is wrong, and smoothing can make the stand-in slide after the window has stopped. Its constants are first guesses, to be judged by eye. All ticks, also for seeing a drag, now follow the display's rate.
- Changes now: a pure rule, `FollowModel`, the tick in `AccessibilityWindowSystem`, the app's window and its strings.
