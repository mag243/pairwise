# Architecture Decision Records

One file per decision: `NNNN-short-title.md`, numbered in order. A number is never reused. If a decision changes, write a new ADR and set the old one to "Superseded by NNNN".

Use `0000-template.md` as the basis.

| No. | Decision | Status |
|---|---|---|
| 0001 | Core in a local Swift package with four modules | Accepted |
| 0002 | Swift Testing as the test framework | Accepted |
| 0003 | Minimum OS version, macOS only | Accepted |
| 0004 | Build and test via `tools/build.sh`, environment via `tools/setup.sh` | Accepted |
| 0005 | SwiftLint alongside swift-format | Accepted |
| 0006 | CI runs by hand, not on every push | Accepted |
| 0007 | Bundle identifier `me.m-domain.pairwise` | Accepted |
| 0008 | CI builds with the newest Xcode on the runner image | Accepted |
| 0009 | Semantic version plus a date-and-time build number | Accepted |
| 0010 | English, Dutch and German | Accepted |
| 0011 | UI tests only when the owner says so | Accepted |
