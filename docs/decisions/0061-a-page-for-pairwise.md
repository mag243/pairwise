# 0061. A page for Pairwise

- **Status:** Superseded by 0067
- **Date:** 2026-11-02
- **Milestone:** M3a

## Context
GitHub Pages already serves the update feed from the branch `gh-pages` (ADR 0058), but its address shows nothing. The owner wants a small page there: what Pairwise does and how to install it, for people who do not want to read a repository.

## Decision
A page at `https://mag243.github.io/pairwise/`, written in Markdown in `tools/site/`, built by GitHub Pages with Jekyll and its Primer theme. `tools/publish.sh` copies that folder to `gh-pages` with every release, so the page and the feed go out together. So `gh-pages` holds the feed and this page, and still no work. The cask's homepage is this page.

## Alternatives
- **A hand-written HTML page:** more to maintain, for a page that is mostly text.
- **The README as the page:** written for people who build Pairwise too.
- **Writing on `gh-pages` directly:** the text would have no history on `main`, and the next release would not know of it.

## Consequences
- Positive: one address to point people at. The page's text is reviewed and versioned with the rest.
- Negative / risks: a change to the page goes out with the next release, or by pushing `gh-pages` by hand. Jekyll copies the feed as it is, since it has no front matter.
- Changes now: `tools/site/`, `tools/publish.sh`, the cask's homepage.
