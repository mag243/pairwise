# 0054. Pairs that last

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
Pairs live in memory, so a quit, a crash or a restart loses them. A window's number lasts as long as its app runs, not across a restart of the app or the Mac, and nothing else identifies a window for certain. Joining the wrong windows would be worse than losing a pair.

## Decision
- **Pairs are saved** to a file in the app's folder in Application Support, after each change: a join, a parting, and the end of a drag or a resize.
- **A saved window has its number, process, app, frame, and a hash of its title.** A title can name a private document, so it is never written as text: SHA-256 is enough to tell whether a title is the same. The file stays on the Mac.
- **A window is found again in the first way that holds, each only if it finds exactly one window:**
  1. The same number and process and app, in the same boot of the Mac. This covers a restart of Pairwise alone.
  2. The same app and the same frame.
  3. The same app, the same title and the same size.
- **A pair comes back only if both windows are found, and they still stand side by side with their tops level. No window is ever moved or resized for it.** So a wrong match can only join two windows that already stood against each other like a pair.
- **What is not found stays saved for two minutes after the start, and is tried once a second,** as apps can open their windows after Pairwise starts. After that it is dropped.
- A file that cannot be read is dropped. Test runs in a debug build neither read nor write this file.

## Alternatives
- **Plain titles in the file:** easier to look into, but it writes the names of the user's documents to disk.
- **Moving found windows back beside each other:** would restore more pairs, but moves a window on a guess.
- **Only by title:** many apps change a title all the time, as a terminal does.
- **Keeping saved pairs for ever:** a pair could suddenly return days later.

## Consequences
- Positive: pairs survive a quit, a crash, a restart of an app and usually of the Mac, without a window moving.
- Negative / risks: a pair whose windows an app reopens elsewhere, or with another size or title, is lost. Two windows of one app with the same frame are not told apart, and count as not found. Starting Pairwise at login is still to come.
- Changes now: `PairwiseCore` (`PairRestore`), the window system, the model, the fake, the plan.
