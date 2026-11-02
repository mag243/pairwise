# 0058. Publishing a release

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3a

## Context
A release has to reach three places: the files people download, the feed Sparkle reads (ADR 0057), and the Homebrew cask (ADR 0059). This repository is public, so nothing needs a second repository. The feed's address is in every installed copy, so it must stay the same for as long as those copies exist. What is published must be exactly the source that is public under the release's tag.

## Decision
`tools/build.sh publish`, run by the owner on their Mac, checks the source, runs `package` and then `tools/publish.sh`.

- **Files.** A GitHub Release in `mag243/pairwise`, tag `v<version>`, with the zip and the disk image, and the changelog section as its notes. `CHANGELOG.md` must have that section.
- **Feed.** GitHub Pages at `https://mag243.github.io/pairwise/appcast.xml`, from a branch `gh-pages` that holds only the feed. It is not a working branch: only `publish` writes to it, and all work stays on `main`.
- **Checks first.** The tree is clean, the tag points at `HEAD`, and `HEAD` is what `origin/main` holds. Nothing public happens before the package is made and the feed is signed.
- **Order.** The release first, then the feed, then the cask, so nothing ever points at a file that is not there yet.
- **Trial run.** `tools/publish.sh --dry-run` signs and writes the feed under `build/publish/` and stops before anything leaves the Mac.
- **Normal releases.** Also at 0.x a release is not marked as a pre-release, so that the repository's latest release is the one to download.

## Alternatives
- **A second, public repository for releases:** only needed when the source is private.
- **Pages from `docs/` on `main`:** would also publish the plans and ADRs as a website, and every release would add a commit to `main`.
- **The feed as a release asset, at `releases/latest/download/appcast.xml`:** no branch, but the feed then depends on which release GitHub counts as latest, and a mistaken release would strand the copies.
- **Releases from CI:** see ADR 0056.

## Consequences
- Positive: one repository, and each release is traceable to its tag.
- Negative / risks: moving the feed later means one last release at the old address that points to the new one. Pages must be on before the first copy goes out.
- Changes now: `publish` in `tools/build.sh`, `tools/publish.sh`, `tools/release_notes.sh`, the README's section on releasing.
