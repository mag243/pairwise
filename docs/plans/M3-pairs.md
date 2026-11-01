# M3 · Pairs: join, move together, share the seam, come apart

**Goal:** Pairwise as people would use it, without any plug-in: bring any two windows together, and they stay a pair until they are pulled apart. Everything so far works on a fixed partner; this makes pairs real.
**ADRs:** 0024, 0028, 0029, 0030 as the base. New ones as marked below, each written before its step.
**Status of this plan:** a proposal. The choices at the end are the owner's, and the steps follow from them.

Not in this milestone: the plug-in (M4), distribution, top and bottom pairs, more than two windows in a group, and more than one display's special cases beyond what the steps name.

## Tasks

### 1. Reach the system through a seam
- [ ] ADR: a thin seam around the Accessibility, window server and capture calls.
- [ ] Put the calls behind small protocols inside `PairwiseWindowSystem`, and test the logic with fakes, up to the 75 % target. The calls themselves stay untested by plain tests, and the stress test covers them.

Done first because everything below adds code to this module.

### 2. Tell a title bar from a control
- [ ] ADR: how a press is taken over. The fixed band of 52 points goes.
- [ ] Ask what is under the pointer through the Accessibility API. On a button, tab, text field or other control, nothing is taken over and the drag passes.
- [ ] A rule table in `PairwiseCore` from role to "drag" or "leave alone", test-first. An unknown role passes.
- [ ] Check by hand: dragging a tab in Safari works, clicks work, a toolbar's empty space moves the pair. Check Terminal, Finder, Safari and one Electron app.

### 3. Pairs as a model
- [ ] `PairwiseCore`, test-first: a pair, which side each window is on, the rules (not a window with itself, a window in one pair only).
- [ ] A window is known by its window number. What happens when one closes, minimizes or goes full screen: the pair ends and the other window stays where it is.
- [ ] Only a press on a window in a pair is taken over. All others pass untouched, and no picture is taken. This also removes the picture on every click.
- [ ] The panel holds the pair in its own order, with the partner on either side.

### 4. Joining
- [ ] ADR: the gesture (choice 1).
- [ ] `PairwiseCore`, test-first: when a dragged window is close enough to another window's edge to join. The snap distance is a named constant.
- [ ] A guide shows where the window will land, and at the release the two click together, with the seam lighting up briefly (the design notes in `PLAN.md`).
- [ ] The heights after joining (choice 2).

### 5. Coming apart
- [ ] ADR, with the gesture of step 4.
- [ ] The gesture pulls one window out, and only that window moves. The pair ends.

### 6. The shared seam
- [ ] A short spike first, as this is the least known part: can Pairwise see a resize soon enough, and should it follow the app's notifications or take over the drag as in ADR 0024? The outcome goes in an ADR.
- [ ] Resizing a window at the seam resizes the other, so the seam stays shared. Outer edges resize one window only.
- [ ] Minimum sizes: the seam stops where either window refuses to go.
- [ ] Measured and judged by hand, as in `docs/reference/`.

### 7. Together in other ways
- [ ] Bringing one window of a pair forward brings the other forward, without taking focus from the first.
- [ ] Minimizing one minimizes the other (choice 3).

### 8. Not losing windows
- [ ] ADR: what a crash leaves behind.
- [ ] Before parking, the windows' places are written to a file; after the release it is cleared. At the next start, Pairwise puts back any windows in that file.
- [ ] A test by killing the app during a drag, in the stress test, on its own windows.

### 9. Pairs that last
- [ ] ADR: how a window is found again after a restart (app, title, size, place), since its number does not survive.
- [ ] Pairs are saved, and restored at the start where both windows are found. A pair that cannot be found with confidence is dropped, and no window is moved.

### 10. The app itself
- [ ] ADR: menu bar app or window (open decision 2 in `PLAN.md`, choice 4).
- [ ] The measurements, the frame rate and the choice of partner app leave the main interface. The permissions stay, explained plainly. The stress test stays.
- [ ] Complete `nl` and `de`, with the translation tools of ADR 0010 brought over.

## Acceptance criteria
- [ ] By hand: two windows of different apps join, move together, share their seam and come apart, without a manual.
- [ ] By hand: a window not in a pair behaves exactly as without Pairwise, including tabs, tiling and snapping.
- [ ] The stress test covers joined pairs, a closed partner and a kill during a drag, and passes.
- [ ] After a kill during a drag, the next start puts the windows back.
- [ ] Coverage targets are met: Core ≥ 90 %, WindowSystem ≥ 75 %, UI state ≥ 70 %.
- [ ] `tools/build.sh ci` is green (when the owner says so, ADR 0011).

## Choices for the owner
1. **How two windows join and come apart.**
   - **A modifier while dragging (proposed):** hold a key while dragging to an edge to join, and hold it while dragging to come apart. Nothing happens by accident, and normal dragging stays normal. The key still has to be chosen, and it must not clash with macOS.
   - **Automatic at the edge:** the most magnetic, but every window dragged past another may join, and an earlier project found telling those apart hard.
   - **A glue mode with a shortcut:** as Window Glue's F9. Clear, but an extra step each time.
2. **Heights after joining.**
   - **The dragged window takes the other's height and top (proposed):** a tidy pair, and the seam runs the full height. It does change one window's size.
   - **Both keep their size, tops level:** nothing is resized, but the pair can look uneven.
3. **Minimize together:** yes (proposed), or leave it for later?
4. **Menu bar app or window.**
   - **A menu bar app with no Dock icon (proposed):** it fits something that runs in the background, and a settings window holds the rest.
   - **A normal app with a window:** simpler, but it sits in the Dock for no reason.
5. **The name.** `PLAN.md` leaves it until before the first release. Renaming later touches the bundle identifier and so the permissions; it needs no decision for this milestone unless "Click!" or another name is already certain.

## Risks
- **The seam** may lag in the way following did, and a picture does not help as easily while the content itself changes size. Step 6 starts with a spike for this reason.
- **Roles under the pointer differ per app,** so step 2 may need several rounds, particularly with Electron apps. An unknown role passes, so the failure is one window moving alone, not a blocked click.
- **Finding windows after a restart** is guesswork for apps with changing titles. Step 9 prefers dropping a pair to moving the wrong window.
- **The event tap now holds up every press** for the time of a window list and an Accessibility call. Step 3 should shorten this by leaving windows without a pair alone early. If an app is slow to answer, step 2's call must not hold input for long.
