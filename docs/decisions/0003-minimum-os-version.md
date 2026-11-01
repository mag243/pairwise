# 0003. Minimum OS version, macOS only

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M0

## Context
macOS 26 brings the latest SwiftUI APIs; older versions widen the reach. Pairwise rests on the Accessibility API and on moving other apps' windows, which iPadOS and iOS do not offer.

## Decision
macOS 15 as the minimum, and no other platform. APIs that exist only on 26 go behind `if #available`.

## Alternatives
- **macOS 26 as the minimum:** less code, but a smaller audience.
- **iPadOS as well, as in an earlier project:** not possible without the API.

## Consequences
- The minimum is set as `MACOSX_DEPLOYMENT_TARGET = 15.0` in `Pairwise.xcodeproj` and as `platforms: [.macOS(.v15)]` in `Packages/PairwiseKit/Package.swift`; a change updates both.
