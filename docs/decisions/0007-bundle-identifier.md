# 0007. Bundle identifier `me.m-domain.pairwise`

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M0

## Context
Every target needs a bundle identifier based on a domain the owner controls. It becomes permanent at the first release, and macOS ties the privacy permissions Pairwise depends on to it. The owner's domain is `m-domain.me`, as in an earlier project.

## Decision
The app uses `me.m-domain.pairwise`, the UI tests `me.m-domain.pairwise.uitests`. Later targets get a suffix on the same base. The choice is final at the first release.

## Alternatives
- **A domain for Pairwise:** none yet; it can still replace this before the first release.

## Consequences
- `PRODUCT_BUNDLE_IDENTIFIER` in `Pairwise.xcodeproj` is the only place the identifier is set.
