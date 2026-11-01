# 0031. A seam around the system calls

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M3

## Context
`PairwiseWindowSystem` is at about 5 % line coverage against a target of 75 %. Much of it is logic that plain tests could reach, were it not mixed with calls that need permissions and real windows. M3 is about to add a lot to this module.

## Decision
- **Two small protocols inside the module** carry every Accessibility and window server call: `AccessibilityElement`, which `AXUIElement` conforms to, and `SystemAccess` for the rest (an app's element, the window list, running apps, displays). The real versions only forward the calls. Tests use fakes, so they need no permission and move no windows.
- **Pure parts are pulled out and tested:** the panel's layout, the conversion of display frames, and counting changed frames (in `PairwiseCore`).
- **The stress test stays in this module but outside the coverage figure.** `tools/build.sh coverage` leaves out `DragStressTest.swift`: it is a tool that drives real windows, not code that runs for users. It is what covers the real calls, by hand (ADR 0027).
- **Left without plain tests, as the seam would be longer than the code:** the forwarding itself, installing the event tap, the display link, and the ScreenCaptureKit calls.

## Alternatives
- **Lowering the target for this module:** the owner's rule says tests are not weakened to finish a task, and most of the logic can be reached.
- **Tests against real windows with a tag:** they need a permission, and CI skips them, so they would not count.
- **Moving the stress test to a target of its own:** the same effect on the figure, with changes to the Xcode project and wider access in the module.

## Consequences
- Positive: the logic of finding windows, moving them and handling failures is tested without a screen.
- Negative / risks: the fakes can differ from the real API, as the earlier test with made-up window lists did (ADR 0026). The stress test stays needed for changes here. If the figure stays under 75 % with this, ScreenCaptureKit needs a seam as well.
- Changes now: `PairwiseWindowSystem`, `tools/build.sh`.
