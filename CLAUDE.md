# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

Pairwise brings Snap Groups to the Mac: two windows of any app, brought together side by side, join, move together, share their seam and come apart again easily, through the Accessibility API and without anything from the apps.

Milestone M0 (skeleton) holds the structure: the macOS app, the package with its four modules, the tools and the rules. M1, the spike, found that a window following through the Accessibility API visibly lags. M2 moves both windows as pictures in one window of Pairwise's own while dragging, live at a chosen frame rate (ADR 0024, 0028, 0029). Joining, the shared seam and coming apart are M3.

**Everything is written in English:** code, identifiers, comments, documentation (plans, ADRs, READMEs), commit messages, PR descriptions and test names. Chat with the owner may be in Dutch.

## How work is organised

- `docs/plans/PLAN.md` is the master plan and the specification: what Pairwise does, the hard part, design notes, milestones, modules, folder layout, test plan, open decisions. Read it before starting a milestone.
- Work milestone by milestone via `docs/plans/M*-*.md`. Work directly on `main`: no branches or PRs unless the owner asks for one (ask first if a branch seems truly necessary). Tick tasks off in the plan file (`- [x]`) and commit that with the work. When all acceptance criteria are met and tests are green, set the status in `docs/plans/README.md` to **Done**.
- New or changed decisions: write an ADR first in `docs/decisions/` (copy `0000-template.md`, next free number, never reuse a number; superseded ADRs get status "Superseded by NNNN"), update `docs/decisions/README.md`, then write code.
- `docs/reference/` is reference material, not a work plan.

## Commands

`tools/build.sh` is **the** way to check, build and test (ADR 0004); don't call `swift test` or `xcodebuild` by hand. `tools/build.sh --help` lists every command.

```sh
tools/setup.sh                        # verify Xcode, install tools, git hooks (idempotent)
tools/build.sh quick                  # check + package tests: gate for a step that leaves the app alone
tools/build.sh verify                 # check + package tests + build the app: gate for an app change
tools/build.sh ci                     # check + package tests + build the app + macOS app tests (default)
tools/build.sh test DragStatsTests     # one suite or test (swift test --filter)
tools/build.sh apptest LaunchTests/testShowsWindow   # only these UI tests (comma-separated; takes the screen)
tools/build.sh check                  # swift-format, SwiftLint, import rules (ADR 0001), translations, shellcheck
tools/build.sh format                 # the only command that rewrites code
tools/build.sh coverage               # package tests with line coverage, per-module targets (PLAN.md, Test plan)
tools/build.sh run                    # build and start the macOS app
tools/build.sh run --drag-stress-test FILE   # the app tests dragging on its own windows; takes over the pointer (ADR 0027)
tools/build.sh run --join-test FILE   # the same for joining and parting, with a picture of the guide (ADR 0027)
tools/build.sh run --seam-test FILE   # measures how well a window follows a resize at a seam; takes over the pointer
tools/build.sh run --seam-look FILE   # saves pictures of a resize at the seam next to FILE; takes over the pointer
tools/build.sh run --record FILE      # the app as usual, recording the screen to FILE for 40 seconds, then it quits
tools/build.sh run --kill-test FILE   # kills the app during a drag of its own windows; then run --kill-check FILE
tools/build.sh run --settings-look FILE   # saves a picture of the settings; --settings-tab N picks a tab
tools/build.sh release                # build the app, Release, and fail if test code is in it (ADR 0050)
```

- Run `quick` after a step that only touches the package and `verify` after any app change; both must be green. `ci` adds the XCUITest smoke tests, which take over the screen: run it only when the owner says so, and ask for it before the owner pushes and at the end of a plan (ADR 0011).
- Pinned versions (Xcode, tool minimums) live only in `tools/versions.env`; rerun `tools/setup.sh` after changing one. CI uses `CI_XCODE_VERSION` (the runner's newest Xcode, ADR 0008), so the code must also build with that older Xcode.
- Output goes to `build/` (`logs/`, `reports/*.xcresult`, `DerivedData/`); on a failure read the log the script names.
- The git hooks (`tools/git-hooks/`) run `build.sh check` before a commit and enforce the commit-message rules below.
- CI (`.github/workflows/ci.yml`) runs only by hand (ADR 0006). `tools/build.sh ci` locally is the real gate; it must be green before the owner pushes.
- Claude Code runs `tools/build.sh`, `swift` and `xcodebuild` outside its sandbox through `sandbox.excludedCommands` in `.claude/settings.local.json`; inside it, SwiftPM's own `sandbox-exec` fails (`sandbox_apply: Operation not permitted`). Entries use `Bash(...)` rule syntax (`"swift *"`, not `"swift"`), and only a standalone call matches: run `tools/build.sh ci`, not `cd … && tools/build.sh ci` or `tools/build.sh ci | tail`. If it still fails, ask the owner instead of working around it.
- Versions: semver in `MARKETING_VERSION` (by hand, a project-level setting); `CFBundleVersion` is stamped `YYYY.MMDD.HHMMNN` by the Run Script phase `tools/xcode/stamp_build_timestamp.sh` on every build (ADR 0009), which needs `ENABLE_USER_SCRIPT_SANDBOXING = NO` on the app target.

## Architecture

Swift 6 strict concurrency. Minimum macOS 15 (ADR 0003); macOS-26-only APIs go behind `if #available`. Pairwise is macOS only: the Accessibility API it rests on has no counterpart on iPadOS or iOS.

Local package `Packages/PairwiseKit`, dependencies strictly one way: **App → UI → WindowSystem → Core**.

- `PairwiseCore` — pure Swift, Foundation only, no system calls, no AppKit/SwiftUI. The rules of pairs, seams and snapping, and the protocols the window system implements.
- `PairwiseWindowSystem` — the real implementation behind Core's protocols, and the only module that touches other apps' windows: the Accessibility API, event taps, ScreenCaptureKit.
- `PairwiseUI` — shared `@Observable` view-models and SwiftUI views.
- `PairwiseTestSupport` — a fake window system and fixtures, used by view-model tests and previews.
- App: `Apps/PairwiseMac`. XCUITest smoke tests in `UITests/PairwiseMacUITests`.

## Hard rules

- Every new rule in `PairwiseCore` gets a test first (test-first). Use Swift Testing (`@Test`, `#expect`, `@Suite`, parameterised `@Test(arguments:)` for rule tables); XCUITest only for smoke tests. Slow or environment-dependent tests get a tag and an `.enabled(if:)` condition, so CI skips them.
- Core tests are pure, never touch the system, and run in < 1 s total. Coverage targets: Core ≥ 90%, WindowSystem ≥ 75%, UI state ≥ 70%.
- Plain test runs need no permission and move no windows: they use the fake window system. A test that needs Accessibility, Input Monitoring or Screen Recording carries a tag and `.enabled(if:)` on an environment variable, and moves only windows it opened itself, never the owner's.
- The Accessibility API and event taps are used only in `PairwiseWindowSystem` (checked by `tools/check_dependencies.sh`). An event tap never swallows or changes an event it does not own, and always lets input through when Pairwise fails.
- `PairwiseCore` must not import AppKit or SwiftUI.
- No `@unchecked Sendable` without an ADR.
- Test code that drives or records the screen goes inside `#if DEBUG`, flags included (ADR 0050).
- Bugs: first a failing test that reproduces the bug, then the fix. The test stays.
- Never disable, skip or weaken tests to complete a task. If it is unclear whether the test or the code is wrong, report it.
- Test style: the test name describes behaviour (`rejectsPairOfWindowOnItself`), one behaviour per test, no waiting on real time, no dependency on test order, no global state.
- Definition of done: all tests pass, new code has tests, and the build has no warnings.

## Swift style

- All code passes `swift-format` (layout, `.swift-format`) and SwiftLint (size, safety and comment rules, `.swiftlint.yml`, ADR 0005). Disable a rule only with `// swiftlint:disable:next <rule>` and a reason on the same line. One primary type per file; files under ~300 lines, functions under ~40 lines and at most three levels of nesting — beyond that, split.
- No magic numbers: limits, sizes, durations and thresholds (snap distance, follow rate, …) are named constants.
- User errors are not programmer errors. A missing permission, a window that has gone or refuses to move, and an action that is not allowed return a typed error/result with a reason the UI can show. `precondition`/`assert` only for programmer errors; never crash on user input or on what another app does.
- All user-facing text goes through a String Catalog (`Localizable.xcstrings`, in the app and in `PairwiseCore`/`PairwiseUI`); no hard-coded UI strings. Languages: English (source), Dutch and German (ADR 0010); every milestone that adds text ends with complete `nl` and `de` translations.
- Logging via `os.Logger` with a subsystem/category; no `print()` in committed code.

## Comments

Comments describe the code **as it is now**: what it does, why, and its contract.

- Every public type and method in `PairwiseCore` and `PairwiseWindowSystem` has a `///` doc comment. Where relevant state the contract: `Precondition:`, `Postcondition:`, `Invariant:` (for types). Check cheap preconditions in code with `precondition()` using the same wording.
- Explain *why* when the code alone doesn't make it obvious (an Accessibility quirk, an app that answers late, a performance trade-off). Don't restate what the code says.
- **Never describe history:** no "previously", "used to", "now uses", "fixed bug where", "refactored". History belongs in git.
- No commented-out code. `TODO:` only with a concrete description of what is missing.

## Git and commits

- Small, complete steps, one commit per step. Reference the plan in the commit body (`Plan: M1`).
- Conventional commits in English: `feat(core): add pair rules`, `fix(windows): …`, `test(core): …`, `docs: …`, `refactor(ui): …`.
- Never bypass git hooks (`--no-verify`).
- **Never push.** The owner pushes; commit locally and say what is ready to push.
- **No AI attribution anywhere:** no `Co-Authored-By` trailers, no "Generated with Claude Code", no mention of Claude or AI in commits, PR descriptions, code or docs; refer to "the agent" where a doc must speak of it. Only names and paths that point at something stay (`CLAUDE.md`, `.claude/`). Also enforced in `.claude/settings.json`.

## Working method

- No new SwiftPM dependencies, tools or plugins without asking.
- If a task conflicts with these rules, `PLAN.md` or an Accepted ADR: report it first, don't silently deviate.
- Logs, probes and scratch output of a working session go to the session's scratchpad, not into the repo.
