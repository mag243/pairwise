# 0006. CI runs by hand, not on every push

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M0

## Context
macOS runner minutes are limited on GitHub's free plan, and the local gates already run everything.

## Decision
`.github/workflows/ci.yml` runs only on `workflow_dispatch`. The job selects the pinned CI Xcode, runs `tools/setup.sh` and `tools/build.sh ci`, and keeps `build/logs` and `build/reports` as an artifact when it fails. Day to day, `tools/build.sh ci` must be green locally before a push.

## Alternatives
- **CI on every push:** uses up the minutes.
- **No CI:** nothing would check that the project builds on a clean machine.

## Consequences
- A regression can reach `main` when the local gate is skipped; the hooks and `CLAUDE.md` guard against that.
- A workflow for releases comes with distribution.
