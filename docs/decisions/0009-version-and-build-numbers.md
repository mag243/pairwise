# 0009. Semantic version plus a date-and-time build number

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M0

## Context
A Mac app has a version users see and a build number. The App Store requires the build number to increase with every upload and to be at most three period-separated integers. The owner wants to see at a glance whether a build is the latest one, and uses this scheme in an earlier project.

## Decision
- **Version:** `MAJOR.MINOR.PATCH` in `MARKETING_VERSION`, by hand, in `Pairwise.xcodeproj`.
- **Build number:** `YYYY.MMDD.HHMMNN`, the date and time of the build plus a two-digit counter within that minute, written by the Run Script phase `tools/xcode/stamp_build_timestamp.sh` on the `PairwiseMac` target.
- The counter lives in `.build-counter` at the repository root (gitignored). The script reads the value back and fails the build when Xcode has regenerated the plist.
- `ENABLE_USER_SCRIPT_SANDBOXING = NO` on the app target: the script sandbox blocks writing the counter file. The project-level default stays `YES`.

## Alternatives
- **Build number passed by `tools/build.sh`:** builds started in Xcode keep build number `1`.
- **A plain incrementing integer:** says nothing about when a build was made.

## Consequences
- The phase runs on every build, which costs a few milliseconds.
- The stamp uses local time; CI sets `TZ: Europe/Amsterdam` to match.
