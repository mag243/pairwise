# Pairwise

*Snap groups for your Mac.* Two windows of any app, brought together side by side, join: they move together, share their seam and come apart again easily, without anything from the apps.

Status: early, version 0.x. Joining, moving together, the shared seam and coming apart work, and pairs last through a quit and a restart.

## Installing

Pairwise needs macOS 15 or later. With [Homebrew](https://brew.sh):

```sh
brew install --cask mag243/tap/pairwise
```

Or download the disk image from the [latest release](https://github.com/mag243/pairwise/releases/latest) and drag Pairwise to Applications. Pairwise updates itself either way, after asking.

To remove it: `brew uninstall --zap pairwise`, or quit it and move it to the Trash. Then also remove it under Privacy & Security in System Settings, where macOS keeps the permissions.

If a permission shows as on but Pairwise says it is missing, turn it off and on again, or remove Pairwise from the list and add it again. macOS ties a permission to the app's signature, so this can happen after running a copy signed differently, such as your own build.

## Using it

Pairwise lives in the menu bar and needs two permissions: Accessibility, to move other apps' windows, and Screen Recording, for the pictures of a pair shown while it is dragged. They stay in memory, and nothing is saved or sent anywhere.

- **Join:** drag a window and press Command over another window, or click the open lock on the seam of two windows side by side. Add Shift to give the dragged window the other's height, and Control for the other choice of windows in the settings.
- **Move together:** drag either window of a pair.
- **Share the seam:** drag the edge between the two windows.
- **Come apart:** click the closed lock on the seam, or press Command while dragging one of the windows.

## Privacy

Pictures of windows stay in memory during a drag: they are not saved or sent anywhere. Once a day, and when you ask, Pairwise fetches its update feed from GitHub, which sends nothing more than any web request does. You can turn that off in the settings.

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

## Releasing

The owner releases from their own Mac, which holds the Developer ID certificate, the notary profile `pairwise-notary` and the Sparkle key under the account `pairwise` ([ADR 0056](docs/decisions/0056-signing-and-notarization.md), [0057](docs/decisions/0057-updates-with-sparkle.md), [0058](docs/decisions/0058-publishing-a-release.md)).

1. Set `MARKETING_VERSION`, add the version's section to `CHANGELOG.md`, and commit.
2. Run `tools/build.sh ci`, then `git push`, then `git tag vX.Y.Z`.
3. Run `tools/build.sh publish`. For a trial first: `tools/build.sh package`, then `tools/publish.sh --dry-run`.

After the very first release, turn on GitHub Pages for the branch `gh-pages`.

## License

[MIT](LICENSE). Updates come through [Sparkle](https://sparkle-project.org), whose licence is [in the app](Apps/PairwiseMac/Resources/Sparkle-LICENSE.txt). The sounds are from [Interface Sounds by Kenney](https://opengameart.org/content/interface-sounds), under CC0. See [`CONTRIBUTING.md`](CONTRIBUTING.md) on contributions.
