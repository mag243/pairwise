# M3b · Screenshots by command

**Goal:** the page shows Pairwise at work, with pictures that one command can make again and that hold nothing of the owner's.
**ADRs:** 0027, 0050, 0061, 0062, 0064, 0065.

Not in this milestone: pictures in both light and dark, translated pictures, a film of a drag.

## What only the owner can do
- Quit a running Pairwise, and say when the run may take the screen and the pointer.
- Judge the pictures before anything is committed or published.
- Push, and publish the page.

## Tasks

### 1. The run
- [x] ADR 0065.
- [x] Demo files in `tools/screenshots/`: a text, and a script that draws a picture.
- [x] `--screenshots` in the debug build: a backdrop, TextEdit and Preview opened and placed, placeholders and default settings whatever is stored.
- [x] The scenes `join`, `pair`, `drag` and `settings`, each checking what it should show.
- [x] It follows the Mac's light or dark and changes no system setting. It refuses missing Screen Recording, and TextEdit or Preview already running.

### 2. The command
- [x] `tools/build.sh screenshots`: runs the scenes, fails when the run did not finish, makes the pictures smaller, and writes them to `tools/site/shots/` as WebP.
- [ ] `tools/build.sh publish-page`: sends `tools/site/` to `gh-pages` without a release, and leaves the feed alone.

### 3. The page
- [x] The owner has judged the pictures in the chat.
- [x] The pictures on the page.
- [x] README and CLAUDE.md name the commands.

## Acceptance criteria
- [x] One command makes all four pictures, and a second run gives the same scenes.
- [x] The menu bar reads as a bar, with Pairwise's icon, a network icon and a fixed clock, and no purple recording icon, real clock or other app's status item.
- [x] Nothing of the owner's shows in any picture.
- [x] The release build holds none of this (`tools/build.sh release`).
- [x] `tools/build.sh ci` is green.
- [ ] The owner has seen the page online.
