# M0 · Skeleton & CI

**Goal:** an empty but complete project that builds, tests and runs in CI.
**ADRs:** 0001–0011

## Tasks
- [x] Create the folder structure from `docs/plans/PLAN.md`, Folder structure.
- [x] `Pairwise.xcodeproj` with the targets `PairwiseMac` (macOS 15+) and `PairwiseMacUITests`.
- [x] `Packages/PairwiseKit/Package.swift` with the modules PairwiseCore, PairwiseWindowSystem, PairwiseUI, PairwiseTestSupport and their test targets; Swift 6 language mode.
- [x] Dependencies according to ADR 0001 (App → UI → WindowSystem → Core).
- [x] One dummy test per module (Swift Testing), plus an XCUITest launch test so the `PairwiseMac` scheme has a test action.
- [x] `CLAUDE.md`, `.swift-format`, `.swiftlint.yml` (ADR 0005), `.gitignore`.
- [x] `README.md`, `CHANGELOG.md`.
- [x] `tools/setup.sh`, `tools/build.sh`, `tools/lib.sh`, `tools/versions.env`, `tools/check_dependencies.sh` and `tools/git-hooks/` (ADR 0004).
- [x] `.github/workflows/ci.yml`: `tools/setup.sh` + `tools/build.sh ci`, by hand (ADR 0006).

## Acceptance criteria
- [x] `tools/build.sh verify` is green (check, package tests, the app and its tests build).
- [x] The Mac app launches and shows an empty window titled "Pairwise" (checked by `LaunchTests`).
- [x] `tools/build.sh ci` is green (takes the screen: when the owner says so, ADR 0011).
- [ ] CI is green on a manual run (Actions > CI > Run workflow; ADR 0006), once the repository has a remote.

## Prompt
> Carry out docs/plans/M0-skeleton-ci.md. First read docs/plans/PLAN.md and ADR 0001, 0002 and 0003. Tick off the tasks in the plan.
