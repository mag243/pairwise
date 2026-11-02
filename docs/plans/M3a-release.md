# M3a · Release: install with Homebrew, update with Sparkle

**Goal:** anyone can install Pairwise and keep it up to date: a signed and notarized app, from a disk image or `brew install --cask mag243/tap/pairwise`, that offers its own updates through Sparkle.
**ADRs:** 0003, 0007, 0009, 0034, 0050, 0053, 0054. New ones as marked below, each written before its step.

Not in this milestone: the plug-in (M4), the Mac App Store, automatic installs without a click, a paid version.

## What only the owner can do
These need the owner's keychain, accounts or judgment, so the agent prepares them and says when:
- Run the release itself, which pushes, publishes and updates the tap.
- Turn on GitHub Pages for the feed.

## Tasks

### 1. A signed, notarized app
- [x] ADR 0056: Developer ID, hardened runtime, notarization with a keychain profile of its own, no unsigned fallback. Releases are made on the owner's Mac; the workflow in CI stays by hand (ADR 0006).
- [x] Confirm the bundle identifier `me.m-domain.pairwise` (ADR 0007) and the name: both are permanent from the first release, and macOS ties the permissions to them.
- [x] `tools/build.sh package`: archive, export, notarize, staple, check with `codesign` and `spctl`, and zip. It stops with a message when something is missing. The check for test code (ADR 0050) runs on this build as well.
- [x] `tools/build.sh package` writes a disk image beside the zip, also notarized, with a window to drag Pairwise into Applications.
- [x] `CHANGELOG.md`, with the changelog section as the release notes.

### 2. The first start, on a Mac that has never seen Pairwise
- [x] The settings window opens by itself with `--show-settings` from `tools/build.sh run`, checked by the owner. The same rule opens it when a permission is missing; that case itself is checked on a release copy in the acceptance criteria.
- [x] Granting a permission starts Pairwise without a restart, and taking one away stops it with all input passing, checked by the owner for both permissions. The menu bar menu says why when a permission is gone.
- [x] A release and a debug build are different signatures to macOS, so permissions went to the release alone. A debug build has a bundle identifier of its own (ADR 0062). The README says how to clear a stale entry after running a copy signed differently.
- [ ] Check how often macOS asks again about Screen Recording for an app that captures windows without its picker, and what Pairwise does in the meantime. A drag must keep working, with or without pictures.

### 3. Updates with Sparkle
- [x] ADR 0057: Sparkle as a package of the app target only, pinned to an exact version (`PairwiseKit` never imports it), the key, the feed, how often it checks, what is sent.
- [x] The key is made with `generate_keys --account pairwise`, and the private key is in the owner's password manager. Its public key: `KW1bHieAwaAFKS5d6Hyq6vQBB0iksihCVTB+cy1hLqs=`. Without an account of its own, Sparkle's tools take the key already in the keychain, which belongs to another app, so every signing step names this account.
- [x] A partial `Info.plist` outside the app's synchronized folder: `SUFeedURL`, `SUPublicEDKey`, `SUEnableAutomaticChecks`.
- [x] The updater starts only in a Release build; a debug build and a test run never offer to replace themselves.
- [x] "Check for Updates…" in the menu bar menu, and a setting for checking automatically, in en, nl and de.
- [x] Pairwise has no Dock icon, so an update found in the background would open behind other windows. Use Sparkle's gentle reminders for background apps, and show that an update waits in the menu bar menu.
- [x] An update never lands in the middle of a drag: the window only appears on a check or a click, and installing always takes the user's click.
- [x] Sparkle's own licence goes along in the app, and About or the README names it.
- [x] The README says what a check sends: only the request for the feed to GitHub, with the app's version. System profiling stays off.

### 4. Publishing
- [x] ADR 0058: GitHub Releases in this repository, and the feed on GitHub Pages at `https://mag243.github.io/pairwise/appcast.xml`, from a branch `gh-pages` that holds only the feed and is not a working branch. The address is in every installed copy, so it does not change afterwards.
- [x] `tools/build.sh publish`, run by the owner: check that the tree is clean and the tag `v<version>` points at `HEAD`, run `package`, then `tools/publish.sh`: sign the zip with Sparkle's key, make the release, add it to the feed, and bump the cask. It stops before anything public when a step fails.
- [x] The version is `MARKETING_VERSION`; the build number keeps growing by itself (ADR 0009), which is what Sparkle compares.

### 5. Homebrew
- [x] ADR 0059: a cask `pairwise` in the existing tap `mag243/homebrew-tap`, with `auto_updates true`, so Homebrew leaves updating to Sparkle.
- [x] The cask sets the minimum macOS, quits Pairwise on uninstall, and with `zap` removes its settings and its records (`parked-windows.json`, `pairs.json`).
- [x] `brew audit` and `brew style` on the cask pass.

### 6. Starting at login, and the right place
- [x] ADR 0060: `SMAppService.mainApp`, as a setting that is off until the user turns it on, in the settings or at the end of the first start.
- [x] When Pairwise runs from elsewhere, such as the disk image, it offers once to move to Applications. Starting at login and the permissions both want one fixed place.
- [ ] A start at login returns earlier pairs and parked windows as a normal start does (ADR 0053, 0054).

### 7. The purple recording icon
- [x] Say why it appears, before people see it: in the Screen Recording permission's text, on the page and in the README.
- [x] By hand, with the debug setting at Still: the icon stays away for a pair and at a seam, with stretching at the seam. So a setting, Still by default (ADR 0063).

### 8. Pictures without any capture, on trial
A third choice beside Still and Live, for dragging with no Screen Recording permission at all. First a trial in the debug build; what follows depends on how it looks by hand.

- [x] By hand: Still and Live as they are, and Settings coming to the front from the menu, also from another desktop.
- [x] Trial, in the debug setting: during a drag and at a seam, each window shows as an empty plane that follows light or dark mode, with the app's icon in its middle, and a title bar holding the three buttons, the icon and the window's title, read through the Accessibility API. Nothing is captured.
- [ ] By hand: does it move and resize cleanly, and how does the jump to the real content at the release feel?
- [ ] Decide with the owner whether it stays, and whether it is the default. If it stays: an ADR first, then Pairwise works with Accessibility alone, the permission is asked only for Still or Live, and the first start, the settings' texts, the page, the README and the translations follow.
- [ ] Moving the real windows stays out: M1 showed that the partner visibly lags (ADR 0024).

### 9. Translations and README
- [x] All new text in en, nl and de (ADR 0010).
- [x] The README says how to install with Homebrew and from the disk image, which permissions Pairwise asks for and why, and how to remove it.

## Tests
- Package tests for every rule that can do without the system: what the updater may do in which build, and the choice to offer a move.
- A package check: the release build contains no test code, Sparkle's parts are signed, and the app passes `spctl`.
- The real checks below are by hand: an update and Gatekeeper cannot be tested on a fake.

## Acceptance criteria
- [x] On the owner's own account, the disk image downloaded from the release opens without a Gatekeeper warning beyond macOS's one-time question, and the app offers the move, explains what it needs and works after the permissions are given. No separate user account: the first-run state is made by resetting the permissions.
- [x] `brew install --cask mag243/tap/pairwise` installs it, and `brew uninstall --zap` leaves nothing behind but what macOS keeps of the permissions. Quitting a running Pairwise on uninstall is not yet seen.
- [x] An installed 0.1.0 updates itself to a test 0.1.1 with one click: permissions stay, pairs come back, no window is lost.
- [x] An update with a wrong signature is refused: a test feed with one byte of the signature changed gave "The update is improperly signed and could not be validated".
- [ ] Starting at login works after a restart of the Mac, and can be turned off.
- [ ] `tools/build.sh ci` is green (when the owner says so, ADR 0011).
