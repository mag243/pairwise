# 0008. CI builds with the newest Xcode on the runner image

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M0

## Context
GitHub's macOS runner images lag behind the Xcode used locally, so CI cannot use the local pin.

## Decision
- `tools/versions.env` has a second pin, `CI_XCODE_VERSION`: the newest Xcode on the runner image that `ci.yml` uses.
- `tools/lib.sh` picks `CI_XCODE_VERSION` when `CI=true` and `XCODE_VERSION` otherwise; `tools/setup.sh` checks against that choice.
- When a runner image with the local Xcode becomes available, `ci.yml` moves to it and `CI_XCODE_VERSION` follows `XCODE_VERSION`.

## Alternatives
- **The local Xcode on CI:** not available on the runner.
- **An older Xcode locally:** gives up the newest tools for the sake of CI.

## Consequences
- The code must also build with the older Xcode.
