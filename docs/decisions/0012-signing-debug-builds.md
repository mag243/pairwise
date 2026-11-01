# 0012. Signing debug builds with Apple Development

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M1

## Context
macOS keeps the Accessibility permission against the app's designated requirement. An ad hoc signature has no team or certificate to name, so that requirement is the code's hash, which changes with every build: each rebuild would ask for the permission again, and a stale entry in System Settings would stay behind. The spike needs many rebuilds with the permission in place. The owner's Mac has an Apple Development identity for team `SP255JXLVN`.

## Decision
- The Debug configuration of the `PairwiseMac` target signs with `Apple Development`, so its designated requirement names the bundle identifier and the team and stays the same across builds.
- Release and the UI test target stay as they are. How releases are signed belongs to distribution (open decision 3 in `PLAN.md`), which this does not settle.
- CI has no certificate: when `CI=true`, `tools/build.sh` signs ad hoc, and nothing on CI needs the permission.
- The App Sandbox stays off (the entitlements file is empty): a sandboxed app cannot control other apps' windows through the Accessibility API.

## Alternatives
- **Ad hoc, granting again after each build:** no setup, but it makes trying the spike tedious and leaves stale entries.
- **Developer ID for debug builds:** also stable, but that identity is for what is given to others.
- **Signing only in `tools/build.sh run`:** leaves the project as it is, but a build started in Xcode would still lose the permission.

## Consequences
- Positive: the permission survives rebuilds, to be confirmed by hand in M1.
- Negative / risks: a build needs the certificate in the keychain; another machine has to set up its own or pass the ad hoc settings.
- Changes now: the Debug settings in `Pairwise.xcodeproj`, the CI case in `tools/build.sh`, open decision 1 in `PLAN.md`.
