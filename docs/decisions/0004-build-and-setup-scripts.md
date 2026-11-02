# 0004. Build and test via `tools/build.sh`, environment via `tools/setup.sh`

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M0

## Context
Checking, building and testing must be possible from the command line, the same way locally, in CI, in the git hooks and by the agent. A new machine must be ready to build with a single command. An earlier project and the owner's other projects use this setup.

## Decision
- **`tools/build.sh`** is *the* way to check, build and test. Subcommands: `check`, `format`, `test [filter]`, `coverage`, `build`, `apptest [filter]`, `run`, `clean` and the composite gates `quick` (check + test), `verify` (check + test + build) and `ci` (verify + apptest, the default). All output goes under `build/`.
- **`tools/setup.sh`** checks and installs the environment, idempotently: Xcode (check only), bash, shellcheck, SwiftLint and xcbeautify via Homebrew, and the git hooks.
- **`tools/versions.env`** pins the versions. A version is changed only there.
- **Git hooks** in `tools/git-hooks/` (`core.hooksPath`): `pre-commit` runs `build.sh check`; `commit-msg` enforces conventional commits and rejects attribution lines such as `Co-Authored-By`.
- **`tools/check_dependencies.sh`** guards the import rules of ADR 0001.
- **Formatting:** `swift-format` from Xcode, line length 100 and 4-space indentation (`.swift-format`).
- Commands for distribution come when Pairwise is ready to ship.

## Alternatives
- **A Makefile:** less suited to the logic and deviates from the other projects.
- **Project generator (XcodeGen/Tuist):** would prevent merge conflicts in `project.pbxproj`, but is an extra tool.

## Consequences
- `CLAUDE.md` refers to `tools/build.sh`; the raw `swift test`/`xcodebuild` commands live only in the script.
- `tools/build.sh` runs `swift` and `xcodebuild`, which start their own `sandbox-exec` and fail inside the agent's sandbox; `.claude/settings.local.json` lists them in `sandbox.excludedCommands`.
