# 0065. Screenshots by command

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3b

## Context
The page (ADR 0061) needs pictures of Pairwise at work, and they should come out the same each time they are made again, for a new release or a changed look. Pictures taken by hand depend on the windows of the moment, and show whatever is on the owner's screen. The page is public, so nothing private may get in.

The pictures must show the menu bar, where Pairwise lives. That bar also holds the clock and the status items of the owner's other apps, which differ per Mac and per day.

## Decision
`tools/build.sh screenshots` makes the pictures. It starts the debug build with `--screenshots`, a run of the test tools of ADR 0027, and writes them to `tools/site/shots/` when every scene has succeeded. Git then shows what changed, and the owner decides what to commit. They are WebP at quality 90 (`cwebp`, from Homebrew), about a thirteenth of the PNG's size, made by this command and not at publishing, so what git shows is what goes online.

- **The windows** are real ones of other apps, as Pairwise's promise is about any app: TextEdit with a text and Preview with a picture, from fixed demo files in `tools/screenshots/`, opened and closed by the run. It refuses to run when either app is already running, so it never touches the owner's documents.
- **The scenes:** joining with the guide, the pair with its closed lock, a drag with placeholders, and the settings tab for pairs. Each scene checks what it should show, and the run fails rather than save a wrong picture.
- **What gets in:** the capture leaves out every app except TextEdit, Preview and Pairwise, so the owner's windows stay out, and a backdrop of Pairwise's own replaces the desktop. The menu bar stays in, with the frontmost app's menus and Pairwise's icon. Leaving out an app does not take its status items or the clock off the bar, so a strip of Pairwise's own lies over the right half of the bar during the run, and shows Pairwise's menu bar icon at a fixed place, with a network icon and a clock at a fixed time, without a date, so it reads as a menu bar and the pictures do not age. The real icon can be hidden by a tool or a notch, or be elsewhere on another Mac. The real bar is see-through, so the backdrop gives it a colour of its own and a thin line below, or it would not read as a bar. So the bar in the pictures is staged: only the app menus are the real ones.
- **No purple recording icon:** macOS shows a purple dot at the right edge of the bar after a capture, also a single one, above every window. So a picture leaves out the screen's rightmost 40 points. The run also uses placeholders, whatever is stored, and checks that its drag got no live frames. It cannot see the dot itself, so that needs a look at the pictures.
- **The settings** are the defaults, without the debug build's Test tab, in a window titled as the release does.
- **Light or dark follows the Mac.** The menu bar cannot be set per app, and the run never changes a system setting, so the pictures have the appearance of the Mac they are made on, and the backdrop goes with it. The owner's Mac is dark, so the page's pictures are dark.
- **Only on request.** It takes over the screen and the pointer, as `ci` does, and needs Accessibility and Screen Recording for the debug build (ADR 0062).
- **Publishing a page alone:** `tools/build.sh publish-page` sends `tools/site/` to `gh-pages` without a release, so new pictures need no new version. Only the owner runs it, as it pushes. It leaves the feed as it is.

## Alternatives
- **Pictures by hand:** different every time, and private content is one mistake away.
- **XCUITest, as Treewise does:** it drives one's own app, while the pictures here are about other apps' windows and about panels that take no input. The test tools already post real drags.
- **Demo windows of Pairwise's own:** the most predictable, but the placeholder would show Pairwise's icon and title, and the picture would not show what the page promises.
- **Cropping the menu bar away:** no status items to worry about, but the owner wants the bar in the picture.
- **The real menu bar:** the owner's status items and the date on a public page, different on every run, and the purple dot unless each picture waits for it to go.

## Consequences
- Positive: the page's pictures can be made again in one command, with nothing of the owner's in them.
- Negative / risks: the run depends on how TextEdit and Preview open a file, and on what macOS draws in the menu bar. The dot's place is macOS's to change, so a picture still needs a look before it is committed. TextEdit and Preview may remember the demo files among their recent documents.
- Changes now: `--screenshots`, a scene file in the test tools, `tools/screenshots/`, `webp` in `tools/setup.sh`, `screenshots` and `publish-page` in `tools/build.sh`, `tools/publish.sh`, `tools/site/`, README, CLAUDE.md.
