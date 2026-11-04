# 0066. The copyright year comes from the build

- **Status:** Accepted
- **Date:** 2026-11-04
- **Milestone:** M3b

## Context
About Pairwise shows the copyright line from `NSHumanReadableCopyright`. Written as a fixed build setting, its year goes stale unless someone remembers to change it every January. The owner wants the year to follow the build.

## Decision
The Run Script phase of ADR 0009, `tools/xcode/stamp_build_timestamp.sh`, also writes `NSHumanReadableCopyright` as `© <year of the build> <COPYRIGHT_HOLDER>` into the built `Info.plist`.
- `COPYRIGHT_HOLDER` is a build setting on the `PairwiseMac` target (Debug and Release).
- The script reads the value back and fails the build when it does not match, as it does for `CFBundleVersion`.

## Alternatives
- **A placeholder in `INFOPLIST_KEY_NSHumanReadableCopyright` that the script replaces:** an incremental build can keep the already stamped plist, so the script would find no placeholder.
- **A year passed by `tools/build.sh` as a build setting:** builds started in Xcode would have no year.
- **A custom About panel that computes the year at launch:** shows the year it runs in rather than the year the build was made, and replaces a standard panel for one line of text.

## Consequences
- Every build, from Xcode, `tools/build.sh`, CI or an archive, carries the year it was built in; a release needs no change in January.
- The year is the build's, so an old release keeps showing its own year.
- The year uses local time, like the build number (ADR 0009).
