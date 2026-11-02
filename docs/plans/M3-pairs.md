# M3 · Pairs: join, move together, share the seam, come apart

**Goal:** Pairwise as people would use it, without any plug-in: bring any two windows together, and they stay a pair until they are pulled apart. Everything so far works on a fixed partner; this makes pairs real.
**ADRs:** 0024, 0028, 0029, 0030 as the base. New ones as marked below, each written before its step.

Not in this milestone: the plug-in (M4), distribution, top and bottom pairs, more than two windows in a group, and more than one display's special cases beyond what the steps name.

## Tasks

### 1. Reach the system through a seam
- [x] ADR: a thin seam around the Accessibility, window server and capture calls.
- [x] Put the calls behind small protocols inside `PairwiseWindowSystem`, and test the logic with fakes, up to the 75 % target. The calls themselves stay untested by plain tests, and the stress test covers them.

Done first because everything below adds code to this module.

### 2. Tell a window drag from everything else
- [x] ADR 0032: a press and its drag events pass until the window has really moved, and only then is the drag taken over. This replaces the proposed table of roles, and the fixed band of 52 points goes.
- [x] `PairwiseCore`, test-first: what counts as a move and as a resize.
- [ ] Check by hand: dragging a tab in Safari works, clicks work, a toolbar's empty space moves the pair. Check Terminal, Finder, Safari and one Electron app.

### 3. Pairs as a model
- [x] `PairwiseCore`, test-first: a pair, which side each window is on, the rules (not a window with itself, a window in one pair only).
- [x] A window is known by its window number. What happens when one closes, minimizes or goes full screen: the pair ends and the other window stays where it is.
- [x] Only a press on a window in a pair is taken over. All others pass untouched, and no picture is taken. This also removes the picture on every click.
- [x] The panel holds the pair in its own order, with the partner on either side.

### 4. Joining
- [x] ADR 0035 and 0036: Command held while dragging.
- [x] `PairwiseCore`, test-first: when a dragged window is close enough to another window's edge to join. The snap distance is a named constant.
- [x] A guide shows where the window will land, and at the release the two click together, with the seam lighting up briefly (the design notes in `PLAN.md`).
- [x] The dragged window keeps its height, with the tops level, and takes the other's height with Shift added (ADR 0040).
- [x] Checked by hand with a real Command key, pressed during the drag (ADR 0039). Option clashed with tiling (ADR 0036).
- [x] A setting says whether Command joins any window or the same app's, and Control during the drag gives the other choice (ADR 0043).
- [x] Checked the setting and Control by hand.

### 5. Coming apart
- [x] Command at a press or during the drag of a pair ends the pair, and only that window moves (ADR 0035, 0036, 0040).
- [x] A lock on the seam shows near the pointer, and a click on it ends the pair with both windows staying in place (ADR 0042).
- [x] Checked by hand, with the lock.

### 6. The shared seam
- [ ] A short spike first, as this is the least known part: can Pairwise see a resize soon enough, and should it follow the app's notifications or take over the drag as in ADR 0024? The outcome goes in an ADR.
- [ ] Resizing a window at the seam resizes the other, so the seam stays shared. Outer edges resize one window only.
- [ ] Minimum sizes: the seam stops where either window refuses to go.
- [ ] Measured and judged by hand, as in `docs/reference/`.

### 7. Together in other ways
- [ ] Bringing one window of a pair forward brings the other forward, without taking focus from the first.
- [ ] Minimizing one minimizes the other (owner's choice 3).

### 8. Not losing windows
- [ ] ADR: what a crash leaves behind.
- [ ] Before parking, the windows' places are written to a file; after the release it is cleared. At the next start, Pairwise puts back any windows in that file.
- [ ] A test by killing the app during a drag, in the stress test, on its own windows.

### 9. Pairs that last
- [ ] ADR: how a window is found again after a restart (app, title, size, place), since its number does not survive.
- [ ] Pairs are saved, and restored at the start where both windows are found. A pair that cannot be found with confidence is dropped, and no window is moved.

### 10. The app itself
- [x] ADR 0034: a menu bar app (open decision 2 in `PLAN.md`, owner's choice 4). Done before step 4, at the owner's wish.
- [x] The menu bar icon, the menu, and the window as settings.
- [ ] The measurements and the frame rate leave the main interface. The permissions stay, explained plainly. The stress test stays.
- [ ] Complete `nl` and `de`, with the translation tools of ADR 0010 brought over.

## Acceptance criteria
- [ ] By hand: two windows of different apps join, move together, share their seam and come apart, without a manual.
- [ ] By hand: a window not in a pair behaves exactly as without Pairwise, including tabs, tiling and snapping.
- [ ] The stress test covers joined pairs, a closed partner and a kill during a drag, and passes.
- [ ] After a kill during a drag, the next start puts the windows back.
- [ ] Coverage targets are met: Core ≥ 90 %, WindowSystem ≥ 75 %, UI state ≥ 70 %.
- [ ] `tools/build.sh ci` is green (when the owner says so, ADR 0011).

## The owner's choices
1. **Joining and coming apart:** a key held while dragging: to an edge to join, away to come apart. Normal dragging stays normal. The key is still to be chosen.
2. **Heights after joining:** each window keeps its own, with the tops level; Command with Shift gives the dragged window the other's height (ADR 0040).
3. **Minimizing:** together.
4. **The app:** a menu bar app with no Dock icon, with a settings window.
5. **The name:** before the first release, as in `PLAN.md`.

## Risks
- **The seam** may lag in the way following did, and a picture does not help as easily while the content itself changes size. Step 6 starts with a spike for this reason.
- **Finding windows after a restart** is guesswork for apps with changing titles. Step 9 prefers dropping a pair to moving the wrong window.
- **The event tap now holds up every press** for the time of a window list and an Accessibility call. Step 3 should shorten this by leaving windows without a pair alone early.
