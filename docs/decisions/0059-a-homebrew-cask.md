# 0059. A Homebrew cask

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3a

## Context
The owner wants Pairwise installable with Homebrew. The owner already has a public tap, `mag243/homebrew-tap`. Homebrew and Sparkle both update apps, and must not get in each other's way. Pairwise is a running menu bar app, and it keeps records outside the app.

## Decision
A cask `pairwise` in `mag243/homebrew-tap`, installed with `brew install --cask mag243/tap/pairwise`. `tools/publish.sh` writes it from `tools/homebrew/pairwise.rb.template` at every release, as the last step.

- `auto_updates true`, so Homebrew leaves updating to Sparkle.
- `depends_on macos: :sequoia`, the minimum of ADR 0003.
- `uninstall quit:`, so an uninstall does not leave Pairwise running without its app.
- `zap` removes the settings, the caches and the records of parked windows and pairs. An uninstall alone keeps them, which is what a reinstall wants.

## Alternatives
- **The official `homebrew/cask` repository:** it asks for a notable project, which Pairwise is not yet.
- **A tap of its own:** one more repository for the same thing.

## Consequences
- Positive: one command to install, and updates need nothing from Homebrew.
- Negative / risks: `brew outdated` does not list Pairwise unless asked with `--greedy`, as for every app that updates itself. The tap is public and lists the owner's other casks beside this one.
- Changes now: `tools/homebrew/`, the last step of `tools/publish.sh`, the README.
