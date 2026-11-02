# 0050. Test code only in debug builds

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
The stress test, the join test, the seam tests and their flags were in every build of the app. Some of them save pictures of the screen to a file, and looking into a problem needed a recording of the screen. The owner pointed out that a function that records the screen is a privacy issue in the final app. Pairwise has the Screen Recording permission, so a build that can do this on a flag would be able to save what is on a user's screen.

## Decision
- All test code that drives or records the screen, its flags and its helper window are inside `#if DEBUG`. A release build holds none of it.
- `ScreenCaptureKit` in a release build serves only the pictures of a pair's two windows while it is dragged or resized. They stay in memory, and nothing is saved.
- A rule in `tools/check_dependencies.sh` requires this of the files concerned, and `tools/build.sh release` builds the release app and fails if the test code can be found in it. `tools/build.sh ci` includes it.
- Under this condition, a recording of the screen (`--record`) can stay as a debug tool.

## Alternatives
- **A separate test app:** the cleanest split, but it needs the same module, and permissions of its own to grant. It can still come.
- **Keeping test code out of the repository and applying it when needed:** nothing guards it, and it goes stale.
- **A flag checked at run time:** the code would still be in the app.

## Consequences
- Positive: a release build cannot save the screen, and this is checked.
- Negative / risks: a problem only a release build shows cannot be looked into with these tools. The test code is not compiled in a release build, so the release build is what shows that the app does not depend on it.
- Changes now: the test files, the app's entry, the two tools, `.swift-format`, `CLAUDE.md`.
