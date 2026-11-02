# 0057. Updates with Sparkle

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3a

## Context
Outside the App Store an app has to update itself. Sparkle checks a feed, downloads the new version, checks its EdDSA signature against a public key in the app, and replaces the app. Whoever holds the private key can push an update to every installed copy, and without it no installed copy can update again. Pairwise has no Dock icon, so an update window that opens by itself would land behind the user's work. Pairwise also promises that it sends nothing of what is on the screen, so what an update check sends must be plain.

## Decision
- **Dependency.** Sparkle 2.10.1 as a Swift package of the app target only, pinned to that exact version, with `Package.resolved` committed. `PairwiseKit` never imports it. Sparkle's licence goes along in the app.
- **Key.** A key of Pairwise's own, in the owner's login keychain under the account `pairwise`, with a copy of the private key in the owner's password manager. Every signing step names this account, because Sparkle's tools otherwise take the keychain's default key, which belongs to another app. The public key is `SUPublicEDKey`.
- **Info.plist.** A partial `Apps/PairwiseMac-Info.plist`, outside the app's synchronized folder so it is not copied as a resource, holds `SUFeedURL`, `SUPublicEDKey` and `SUEnableAutomaticChecks`.
- **Checking.** Once a day by Sparkle's default, without first asking in a dialog, and with a setting to turn it off. System profiling stays off: a check asks GitHub for the feed, which shows no more than any request does.
- **Installing.** Always after the user's click, never silently.
- **Without a Dock icon.** Sparkle's gentle reminders: an update found in the background does not take the focus, and the menu bar menu says that one waits. Its item opens the update.
- **Only in a Release build.** A debug build and a test run never start the updater, so they never offer to replace themselves. Their menu item and setting are off.

## Alternatives
- **Asking before the first automatic check** (Sparkle's default): one more dialog on a first start that already asks for two permissions.
- **Installing silently:** a restart in the middle of a drag leaves windows parked until the next start.
- **Our own update check:** no dependency, but no verified download and no replacing of the app.
- **Sharing the key with another app:** a leak would then reach both.

## Consequences
- Positive: users hear of new versions and install with one click, and every update is signed twice, with the Developer ID and with Sparkle's key.
- Negative / risks: losing the private key strands every installed copy, and leaking it lets someone else sign updates. The feed's address is in every installed copy.
- Changes now: the package in `Pairwise.xcodeproj`, the partial `Info.plist`, `Updater`, the menu item and setting with nl and de strings, the README.
