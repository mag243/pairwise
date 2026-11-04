# 0067. The download page

- **Status:** Accepted
- **Date:** 2026-11-04
- **Milestone:** M3b

## Context
The page of ADR 0061 is Markdown in GitHub's Primer theme. It reads as documentation, and downloading takes a trip through the release page, where a visitor has to pick the right file. The owner wants a download page as good as Treewise's: it says at once what Pairwise does, and one click downloads it. A stable link to the newest disk image does not exist, as the file names hold the build number.

## Decision
- **`tools/site/index.html` is the page,** one file with its styles, no scripts, and no outside fonts or trackers. It replaces `index.md`. The source is public, so unlike Treewise's the page stays in this repository.
- **The page is a pair:** two panes in the colours of the icon, joined by its amber seam, which runs down the whole page. A section's heading is in the left pane and its text in the right. The pictures of a pair lie across the seam, with their own seam on the page's. Below 720 points the seam moves to the left edge and the panes become one.
- **One movement:** on load the two halves of the title come together and the lock closes, without it when the visitor asks for reduced motion.
- **The pictures stay dark** (ADR 0065): they follow the page's light and dark panes as they are, framed by their own backdrop.
- **The download button** holds a link to the latest release in the source (`data-download`). `tools/publish.sh` writes the newest disk image's address into every copy it publishes, taken from the feed's newest item, whose zip has the same name. So a release and `publish-page` both go out with the right link, and `main` needs no commit for it.
- **No Jekyll:** a `.nojekyll` file makes Pages serve the branch as it is. The page has nothing to build.
- **Publishing replaces the page:** everything on `gh-pages` except the feed is removed before `tools/site/` is copied, so a file that left `tools/site/` also leaves the site.

## Alternatives
- **Keeping Markdown with a theme of our own:** still a build for one page, and the seam needs its own markup anyway.
- **A stable file name for the disk image in each release:** `releases/latest/download/Pairwise.dmg` needs no writing into the page, but the releases that exist have no such file.
- **A script that asks GitHub's API for the newest file:** a request to another site on every visit.
- **Reading the link from the published page:** the first publish has no such page to read it from.

## Consequences
- Positive: one click to download, and a page that shows what Pairwise is before any text is read.
- Negative / risks: the link is as old as the last publish, and depends on the zip and the disk image of a release having the same name. Text and pictures are updated by hand. Styles live in the page, so it is longer than the Markdown was.
- Changes now: `tools/site/`, `tools/publish.sh`. Supersedes ADR 0061.
