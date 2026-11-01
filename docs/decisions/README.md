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
| 0012 | Signing debug builds with Apple Development | Accepted |
| 0013 | How the spike follows the pointer | Superseded by 0028 |
| 0014 | A stand-in while dragging | Accepted |
| 0015 | Moving the stand-in on drag events, and raising the partner | Superseded by 0028 |
| 0016 | The picture at the press, and measuring the grip with a still pointer | Superseded by 0028 |
| 0017 | Holding the stand-in back | Superseded by 0018 |
| 0018 | Following the window server's place of the dragged window | Superseded by 0028 |
| 0019 | Looking ahead with the pointer's movement | Superseded by 0028 |
| 0020 | Comparing the stand-in with the real window | Superseded by 0028 |
| 0021 | Predicting the stand-in, in step with the display | Superseded by 0022 |
| 0022 | No prediction for the stand-in | Superseded by 0028 |
| 0023 | Testing whether a window drag can be held back | Accepted |
| 0024 | One window of Pairwise's own while dragging | Accepted |
| 0025 | The panel waits a moment after placing | Accepted |
| 0026 | The window under the pointer comes from the window server | Accepted |
| 0027 | A stress test of dragging, run by the agent | Accepted |
| 0028 | One window while dragging is the way; the rest goes | Accepted |
| 0029 | Live pictures while dragging | Accepted |
| 0030 | Moving a window without its animation | Accepted |
