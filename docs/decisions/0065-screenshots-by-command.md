# 0065. Screenshots by command

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3b

## Context
The page (ADR 0061) needs pictures of Pairwise at work, and they should come out the same each time they are made again, for a new release or a changed look. Pictures taken by hand depend on the windows of the moment, and show whatever is on the owner's screen. The page is public, so nothing private may get in.

The pictures must show the menu bar, where Pairwise lives. That bar also holds the clock and the status items of the owner's other apps, which differ per Mac and per day.

## Decision
`tools/build.sh screenshots` makes the pictures. It starts the debug build with `--screenshots`, a run of the test tools of ADR 0027, and writes them to `tools/site/shots/` when every scene has succeeded. Git then shows what changed, and the owner decides what to commit.

- **The windows** are real ones of other apps, as Pairwise's promise is about any app: TextEdit with a text and Preview with a picture, from fixed demo files in `tools/screenshots/`, opened and closed by the run. It refuses to run when either app is already running, so it never touches the owner's documents.
- **The scenes:** joining with the guide, the pair with its closed lock, a drag with placeholders, and the settings tab for pairs. Each scene checks what it should show, and the run fails rather than save a wrong picture.
- **What gets in:** the capture leaves out every app except TextEdit, Preview and Pairwise, so the owner's windows, status items and clock stay out, and a backdrop of Pairwise's own replaces the desktop. The menu bar stays in.
- **No purple recording icon:** macOS shows it for a capture that keeps running, as in Live (ADR 0063, 0064). The run uses placeholders, whatever is stored, checks that its drag got no live frames, and takes each picture as a single capture.
- **The settings** are the defaults, without the debug build's Test tab, in a window titled as the release does.
- **Light only,** as the page is. The menu bar follows the system, so the run refuses a Mac in dark mode.
- **Only on request.** It takes over the screen and the pointer, as `ci` does, and needs Accessibility and Screen Recording for the debug build (ADR 0062).
- **Publishing a page alone:** `tools/build.sh publish-page` sends `tools/site/` to `gh-pages` without a release, so new pictures need no new version. Only the owner runs it, as it pushes. It leaves the feed as it is.

## Alternatives
- **Pictures by hand:** different every time, and private content is one mistake away.
- **XCUITest, as Treewise does:** it drives one's own app, while the pictures here are about other apps' windows and about panels that take no input. The test tools already post real drags.
- **Demo windows of Pairwise's own:** the most predictable, but the placeholder would show Pairwise's icon and title, and the picture would not show what the page promises.
- **Cropping the menu bar away:** no status items to worry about, but the owner wants the bar in the picture.

## Consequences
- Positive: the page's pictures can be made again in one command, with nothing of the owner's in them.
- Negative / risks: the run depends on how TextEdit and Preview open a file, and on what macOS draws in the menu bar. On a Mac with a notch, status items can hide behind it, so a picture still needs a look before it is committed. TextEdit and Preview may remember the demo files among their recent documents.
- Changes now: `--screenshots`, a scene file in the test tools, `tools/screenshots/`, `screenshots` and `publish-page` in `tools/build.sh`, `tools/publish.sh`, `tools/site/`, README, CLAUDE.md.
