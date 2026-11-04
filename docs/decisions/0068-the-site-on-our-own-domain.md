# 0068. The site on our own domain

- **Status:** Accepted
- **Date:** 2026-11-04
- **Milestone:** M3b

## Context
The page and the feed are at `mag243.github.io/pairwise` (ADR 0058, ADR 0061). That address is poor to share and ties every link to a GitHub account. The owner has `m-domain.me`, with DNS at Cloudflare, verified for GitHub Pages in their account, and Treewise is already at `treewise.m-domain.me`.

## Decision
- **The site is at `https://pairwise.m-domain.me/`,** through the custom domain setting of GitHub Pages for this repository, with a `CNAME` file in `tools/site/` and HTTPS enforced. This replaces the feed's address in ADR 0058; the rest of that decision stands.
- **DNS:** a CNAME record `pairwise` to `mag243.github.io`, DNS only, as Cloudflare's proxy keeps GitHub from issuing the certificate.
- **The order matters:** the DNS record comes first, then the `CNAME` file on `gh-pages`, then HTTPS enforced, and only then a release with the new address. GitHub redirects the old address as soon as it sees the file, so the name has to resolve by then.
- **The app, the cask and the docs** use the new address: `SUFeedURL`, the cask's homepage and livecheck, and the README.

## Alternatives
- **Keeping the GitHub address:** no dependency on the domain, but a poorer link to share.
- **One last release at the old address that points to the new one,** as ADR 0058 foresaw: not needed while GitHub redirects the old address, as it does for Treewise's feed.
- **Cloudflare's proxy with its own certificate:** a layer in front of the update feed for nothing this site needs.

## Consequences
- Positive: one short address, the same form as Treewise's, and the site can leave GitHub later without changing it.
- Negative / risks: copies up to 0.2.1 keep reading the old address and depend on GitHub's redirect. Every copy's updates depend on the domain staying registered and on this record pointing at GitHub.
- Changes now: `tools/site/CNAME`, `Apps/PairwiseMac-Info.plist`, `tools/homebrew/pairwise.rb.template`, README.
