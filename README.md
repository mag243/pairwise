# Pairwise

*Snap groups for your Mac.* Two windows of any app, brought together side by side, join: they move together, share their seam and come apart again easily, without anything from the apps.

Status: in development, not yet released. Joining, moving together, the shared seam and coming apart work; pairs do not yet survive a restart. See [`docs/plans/README.md`](docs/plans/README.md) for the milestones and their status.

## Using it

Pairwise lives in the menu bar and needs two permissions: Accessibility, to move other apps' windows, and Screen Recording, for the pictures of a pair shown while it is dragged. They stay in memory, and nothing is saved or sent anywhere.

- **Join:** drag a window and press Command over another window, or click the open lock on the seam of two windows side by side. Add Shift to give the dragged window the other's height, and Control for the other choice of windows in the settings.
- **Move together:** drag either window of a pair.
- **Share the seam:** drag the edge between the two windows.
- **Come apart:** click the closed lock on the seam, or press Command while dragging one of the windows.

## Requirements

- macOS with Xcode 27.2 (the exact version is pinned in [`tools/versions.env`](tools/versions.env))
- [Homebrew](https://brew.sh)

## Getting started

```sh
tools/setup.sh          # checks Xcode; installs SwiftLint, shellcheck, xcbeautify, bash,
                        # and the git hooks
tools/build.sh verify   # check + package tests + build the app; leaves the screen alone
tools/build.sh          # the same + a release build + macOS app tests, which take the screen
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

## License

[MIT](LICENSE). The sounds are from [Interface Sounds by Kenney](https://opengameart.org/content/interface-sounds), under CC0. See [`CONTRIBUTING.md`](CONTRIBUTING.md) on contributions.
