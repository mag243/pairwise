# 0062. A debug build of its own

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3a

## Context
ADR 0012 keeps the permissions through a rebuild by signing debug builds with Apple Development. A release signs with the Developer ID. macOS keeps one permission per bundle identifier, tied to one signature, so with a release in Applications the owner's debug build could not get its permissions: they went to the release. Both also shared settings and records of parked windows and pairs.

## Decision
A debug build has the bundle identifier `me.m-domain.pairwise.debug` and shows as "Pairwise Debug". A release stays `me.m-domain.pairwise` (ADR 0007). Each has its own permissions, settings and records, so they can both be installed. They should not run at the same time: both would take over the same drags.

## Alternatives
- **Removing the release while developing:** every switch asks for the permissions again, and testing a release gets harder.
- **Resetting the permissions at each switch:** the same, with one more step.

## Consequences
- Positive: the owner can use a release every day and still develop.
- Negative / risks: System Settings lists two apps. `tools/build.sh run` stops when a release runs, as both have the same process name, so quit it first.
- Changes now: the Debug configuration of the app target, and the records folder follows the bundle identifier. The debug build asks for its permissions once.
