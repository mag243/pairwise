# 0011. UI tests only when the owner says so

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M0

## Context
XCUITest drives the real app with the real mouse and keyboard, so the owner cannot work on the same Mac while the tests run, and their typing can break a test. For Pairwise, whose subject is windows and dragging, that holds all the more.

## Decision
`tools/build.sh verify` runs check, the package tests and the app build, and is the gate after an app change. `ci`, with the UI tests, runs only when the owner says it may, and at the latest before the owner pushes and at the end of a plan.

## Alternatives
- **UI tests in a macOS virtual machine:** leaves the screen free, but needs a new tool and much setup.
- **UI tests after every change:** the owner could not work meanwhile.

## Consequences
- The owner can keep working while the agent builds and tests.
- A UI regression shows up later, at the next `ci`.
