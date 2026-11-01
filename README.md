# Pairwise

*Snap groups for your Mac.* Two windows of any app, brought together side by side, join: they move together, share their seam and come apart again easily, without anything from the apps.

Status: early development; nothing functional yet. See [`docs/plans/README.md`](docs/plans/README.md) for the milestones and their status.

## Requirements

- macOS with Xcode 27.2 (the exact version is pinned in [`tools/versions.env`](tools/versions.env))
- [Homebrew](https://brew.sh)

## Getting started

```sh
tools/setup.sh          # checks Xcode; installs SwiftLint, shellcheck, xcbeautify, bash,
                        # and the git hooks
tools/build.sh verify   # check + package tests + build the app; leaves the screen alone
tools/build.sh          # the same + macOS app tests, which take the screen
tools/build.sh run      # build and start the macOS app
tools/build.sh --help   # every command
```

`tools/setup.sh --with-claude` also checks that the Claude Code CLI is installed.

## Layout

| Path | Contents |
|---|---|
| `Apps/PairwiseMac` | The macOS app |
| `Packages/PairwiseKit` | `PairwiseCore`, `PairwiseWindowSystem`, `PairwiseUI`, `PairwiseTestSupport` and their tests |
| `UITests/PairwiseMacUITests` | XCUITest smoke tests |
| `docs/plans` | The master plan and one plan per milestone |
| `docs/decisions` | Architecture decision records |
| `docs/reference` | Reference material |
| `tools` | Setup, build, git hooks and pinned versions |

The rules for working in this repository are in [`CLAUDE.md`](CLAUDE.md).
