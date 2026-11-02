# 0034. A menu bar app

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
Pairwise runs in the background and is only noticed when two windows move together, so a Dock icon and a window serve no purpose in daily use. The owner chose a menu bar app with no Dock icon (open decision 2 in `PLAN.md`), and asked for it before joining is built.

## Decision
- The app has `LSUIElement` set, so it has no Dock icon, and a `MenuBarExtra` holds a switch for moving pairs, Settings… and Quit.
- The window that exists now becomes the settings window. It opens at launch only when a permission is missing, as the app is of no use until then, or when asked for with `--show-settings`, which the UI test uses.
- Moving pairs starts by itself at launch when both permissions are there.
- The menu bar icon is the shape of the app icon in one colour, as a template image, drawn by `tools/icon/make_icon.swift`.

## Alternatives
- **An `NSStatusItem` by hand:** more code for what `MenuBarExtra` already does.
- **Keeping the window until step 10:** the plan's order, but the first real function would then arrive in a shape it will not keep.

## Consequences
- Positive: the app takes the place it will keep, and it starts working without a click.
- Negative / risks: `tools/build.sh run` waits until the app quits, which now takes the menu's Quit. Whether the shape reads well at menu bar size is to be judged by hand. The event tap runs whenever moving pairs is on, so every press costs one window list.
- Changes now: the app's scenes and Xcode settings, the icons, the UI test, the strings, the plan.
