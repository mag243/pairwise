# 0005. SwiftLint alongside swift-format

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M0

## Context
`CLAUDE.md` sets rules that swift-format cannot check: functions under ~40 lines, files under ~300 lines, at most three levels of nesting, no `print()`, no force unwraps, and comments without history or commented-out code. Unchecked, those rules erode, especially when the agent writes much of the code.

## Decision
- **swift-format** owns layout (`.swift-format`).
- **SwiftLint** (via Homebrew, minimum version in `tools/versions.env`) checks the rules above with `.swiftlint.yml`, the same configuration as an earlier project. Rules that clash with swift-format are disabled.
- `tools/build.sh check` runs `swiftlint lint --strict`: every warning fails the check, and therefore the pre-commit hook.
- `tools/build.sh format` runs `swiftlint --fix` first and swift-format second, so swift-format's layout has the last word.
- Custom rules: `no_print`, `no_history_in_comments` and `no_commented_out_code`.
- An exception in code (`// swiftlint:disable:next <rule>`) is allowed only with a reason on the same line.

## Alternatives
- **Only swift-format, configured more strictly:** does not cover function and file length or the comment rules.
- **SwiftLint as a SwiftPM build-tool plugin:** adds a package dependency and slows the build.

## Consequences
- The thresholds in `.swiftlint.yml` follow `CLAUDE.md`; a change updates both.
- The custom comment rules are regex-based and can raise false alarms; then the wording is changed, not the rule disabled.
