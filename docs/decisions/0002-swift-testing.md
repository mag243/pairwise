# 0002. Swift Testing as the test framework

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M0

## Context
The core of Pairwise consists of rule tables (snap or not, which edge, how a seam moves). These are best tested with parameterized tests.

## Decision
Unit and integration tests in **Swift Testing** (`@Test`, `#expect`, `@Test(arguments:)`, tags). XCUITest only for a few UI smoke tests.

## Alternatives
- **XCTest:** familiar, but more cumbersome for parameterized tests.

## Consequences
- Slow or environment-dependent tests get a tag and an `.enabled(if:)` condition on an environment variable, so a plain run skips them; `swift test` cannot filter on tags, only on names.
