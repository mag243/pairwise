# 0056. Signing and notarization

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3a

## Context
Pairwise goes out outside the Mac App Store, which cannot host an app that moves other apps' windows through the Accessibility API. A Mac only opens such an app without a warning when it is signed with a Developer ID and notarized by Apple, and Homebrew disables casks that fail this check. The certificate's private key and the notary credentials must never be in this repository, which is public. Releases are rare and made by the owner.

## Decision
`tools/build.sh package` archives the app, exports it with the Developer ID, notarizes and staples it, checks it, and writes a zip and a disk image to `build/release/`.

- **Export.** `xcodebuild -exportArchive` with `tools/ExportOptions-mac.plist`: method `developer-id`, manual signing with the "Developer ID Application" certificate of team `SP255JXLVN`. The app keeps the hardened runtime and its empty entitlements. `tools/build.sh export` stops after this step.
- **Notarization.** `xcrun notarytool submit --wait` with an App Store Connect API key in a keychain profile, `pairwise-notary`, which the owner makes once with `notarytool store-credentials`. When Apple rejects the app, the script saves Apple's log.
- **Checks.** `codesign --verify --strict` and `spctl --assess` must pass, and the exported app must hold no test code (ADR 0050).
- **Disk image.** Beside the zip, for people who download by hand: the app and a link to Applications, signed and notarized itself. `dmgbuild`, pinned in `tools/versions.env`, lays it out without driving Finder, in a Python environment under `build/`, made only when packaging.
- **No fallback.** Without a certificate or a profile the command stops before it builds, and says what is missing, so an unsigned copy can never be released by mistake.
- **On the owner's Mac.** Releases are made there, and CI holds no certificate and no credentials.

## Alternatives
- **Releases from CI:** every secret would sit in a public repository's settings, for a job the owner runs by hand anyway (ADR 0006).
- **Notarizing with an Apple ID:** ties releases to a person's two-factor login; an API key can be revoked by itself.
- **Only a zip:** enough for Homebrew and Sparkle, but a person who downloads it gets the app in Downloads, where the permissions and starting at login should not settle.
- **`create-dmg` or a Finder script:** drives Finder, which needs Automation permission and is fragile.

## Consequences
- Positive: Pairwise opens without a warning on any Mac, and Homebrew accepts it.
- Negative / risks: a release needs the network and Apple's service and takes minutes. The certificate expires after five years. Permissions on macOS follow the signature, so a release copy and a debug build count as different apps.
- Changes now: `tools/ExportOptions-mac.plist`, `tools/dmg/`, `export` and `package` in `tools/build.sh`, `DMGBUILD_VERSION`, `CHANGELOG.md`.
