# Pairwise · plan

**Status:** started 2026-11-01. The skeleton (M0) is in place; nothing functional is built. Progress per milestone is in `README.md` beside this file.
**Subtitle:** *Snap groups for your Mac.*

## Why
an earlier project tried magnetic windows (in an earlier project) and dropped them (ADR 0043): joining windows does not belong in a file manager. Joining *any* two windows, like Snap Groups in Windows 11, belongs in an app of its own. Pairwise fits the an earlier project family by name.

## What it does
- Two windows of any app, brought together side by side, join: they move together, share their seam (resizing one resizes the other), and come apart again easily.
- The MagSafe feel: they click together and come apart just as easily.
- Without anything from the apps: it works for every window, through the Accessibility API.

## What exists already (2026-10-31)
- **Window Glue** (github.com/Conxt/WindowGlue, MIT, ~950 lines of Swift): a menu bar app. You switch on a "glue mode" (F9), drag a window to another, it snaps and the two act "(mostly) as one"; shake to unglue. It uses Swindler (Accessibility API) and moves the partner after each "window moved" event, so the partner lags behind. All four sides, a shared seam (one edge changed resizes the partner), minimize together, bring the partner forward. Links live only in memory. Hobby quality: `print()`, no tests.
- **Split** (splitformac.com, $4.99): keeps two windows paired with a shared divider that resizes both and swaps sides; moving together is not mentioned.
- **FlowSnap** (GitHub): "Window Groups" that move together, also across displays; small project.
- **Rectangle, Magnet, Moom, Loop, macOS tiling:** place windows, do not join them. **yabai, AeroSpace, Amethyst:** tile everything, for enthusiasts.
- **Names taken:** Snapset (snapset.co, a Mac workspace manager), Magnet; Lodestone is close to Loadstone (a window snapping app). Domains pairwise.app and pairwiseapp.com answer (likely taken); pairwise.dev and getpairwise.app did not answer.

## The hard part: following without lag
A separate app cannot make another app's window a child window (`addChildWindow` works within one process only), so the window server cannot move the pair as one. Window Glue's lag comes from waiting for move notifications. Ways around it, in order:

1. **Follow the pointer.** An event tap sees the drag start on a title bar; Pairwise keeps the grip offset and moves the partner 60–120 times a second from the pointer, through the Accessibility API (as an earlier project's guide did). The limit is how fast the other app handles a move.
2. **A stand-in while dragging.** At the start of a drag, Pairwise takes a picture of the partner (ScreenCaptureKit), shows it in a window of its own that follows the pointer without lag, hides the real partner, and puts it in place on release. No visible lag; needs the screen recording permission as well.
3. **A Pairwise plug-in for apps** (an SDK apps embed), as an extra on top, never a requirement:
   - It does **not** remove the limit between two apps: the dragged window reports where it is, and the plug-in in the other app moves its own window; still a message between two processes, so a frame or two behind. Faster than the Accessibility API, not instant.
   - Two windows of the **same** app can be joined as child windows by the plug-in: smooth, as in an earlier project.
   - Its real worth is knowledge: which windows are documents (not palettes or dialogs), minimum widths, tabs, full screen, restoring after a restart. Those were the cases that broke an earlier project's magnetic windows.
   - The catch: other developers embed it only once Pairwise has many users, which needs it to work well without it. First and mainly for our own apps.

## Design notes
- **An explicit glue mode or gesture** (as Window Glue's F9) avoids guessing whether a drag means "join" or "just move"; an earlier project found that hard.
- Snap on release, with a guide while dragging; the seam lights up when they join.
- Coming apart: a modifier while dragging, a shortcut, or a button on the seam.
- Keep pairs across restarts where the windows can be found again.
- Permissions: Accessibility (required), Input Monitoring for the event tap, Screen Recording only for the stand-in. Magnet is in the Mac App Store, so that route exists.

## Order
1. A spike: an app that follows the pointer and moves a Finder window beside the dragged one through the Accessibility API. Does it feel smooth enough?
2. If not, the stand-in while dragging.
3. Pairwise without plug-in: join, move together, the shared seam, coming apart, restoring.
4. The plug-in, first in our own apps only; magnetic windows could come back to our own apps through Pairwise.
5. Only if Pairwise has users: the plug-in public for other developers.

## Milestones
- **M0, skeleton & CI:** the structure below, with no function; `M0-skeleton-ci.md`.
- **M1, spike:** step 1 of the order above. Its result, smooth enough or not, decides whether M2 is needed.
- **M2, the stand-in while dragging:** step 2, only if M1 is not smooth enough.
- **M3, Pairwise without plug-in:** step 3.
- **M4, the plug-in in our own apps:** step 4.
- **M5, the plug-in public:** step 5, only if Pairwise has users.

## Modules
Local package `Packages/PairwiseKit`, dependencies one way: App → UI → WindowSystem → Core (ADR 0001).

- `PairwiseCore`: the rules of pairs, seams and snapping, and the protocols the window system implements. Pure Swift, Foundation only.
- `PairwiseWindowSystem`: the real implementation behind those protocols; the Accessibility API, event taps, ScreenCaptureKit.
- `PairwiseUI`: shared view-models and SwiftUI views.
- `PairwiseTestSupport`: a fake window system and fixtures.

## Folder structure
```
Apps/PairwiseMac/                 the macOS app, its entitlements and resources
Packages/PairwiseKit/Sources/     the four modules
Packages/PairwiseKit/Tests/       one test target per module
UITests/PairwiseMacUITests/       XCUITest smoke tests
Pairwise.xcodeproj/               the app and UI test targets, one shared scheme
docs/plans/                       this plan, one plan per milestone
docs/decisions/                   ADRs
docs/reference/                   reference material
tools/                            setup, build, hooks, pinned versions
```

## Test plan
- **Core:** pure rule tables in Swift Testing, under a second in total, at least 90 % line coverage.
- **WindowSystem:** at least 75 %, through a thin seam around the system calls. Tests against real windows carry a tag and `.enabled(if:)`, need a permission, and move only windows they opened themselves.
- **UI state:** at least 70 %, against the fake window system.
- **Smoke tests:** a few in XCUITest, only when the owner says so (ADR 0011).
- **Feel:** whether following is smooth cannot be tested automatically; it is judged by hand, with the measured rate and delay noted in `docs/reference/`.

## Open decisions
1. **Keeping the Accessibility permission while developing:** settled in ADR 0012.
2. **Menu bar app or windowed app.** M0 shows a window only to have something to launch. Decide in M1 or M3.
3. **Distribution:** Developer ID or the Mac App Store, and whether the App Store allows what Pairwise needs. an earlier project's route (signed, notarized, disk image, Sparkle, tap) is the default; its tools come over when Pairwise is ready to ship.
4. **The name and the domain,** see What exists already; before the first release.
