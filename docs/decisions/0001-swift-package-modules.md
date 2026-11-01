# 0001. Core in a local Swift package with four modules

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M0

## Context
Pairwise's rules (when two windows join, how a seam divides space, where a partner goes) must be testable quickly and without permissions, also outside Xcode. The code that touches other apps' windows needs permissions and real windows, so it cannot be tested that way, and it should stay small and in one place.

## Decision
One local package `Packages/PairwiseKit` with the modules:
- `PairwiseCore`: pure Swift, Foundation only, no system calls, no UI frameworks.
- `PairwiseWindowSystem`: the real implementation behind protocols from Core: the Accessibility API, event taps, ScreenCaptureKit. It may import AppKit (for `NSRunningApplication` and `NSWorkspace`), not SwiftUI.
- `PairwiseUI`: shared view-models and SwiftUI views.
- `PairwiseTestSupport`: a fake window system and fixtures.

Dependencies run one way: App → UI → WindowSystem → Core. The Accessibility API and event taps appear only in `PairwiseWindowSystem`.

## Alternatives
- **Everything in the app target:** less setup, but poorly testable.
- **A separate repo per module:** too heavy for a solo project.

## Consequences
- Core tests run in a few seconds, also in CI, without any permission.
- `tools/check_dependencies.sh` guards the import rules that `Package.swift` cannot express.
