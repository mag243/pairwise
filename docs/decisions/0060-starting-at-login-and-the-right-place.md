# 0060. Starting at login, and the right place

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3a

## Context
Pairwise is of use only while it runs, so people will want it to start with the Mac. Starting at login ties to where the app is, and an app left on a disk image or in Downloads breaks both that and updates: a disk image is read-only, and macOS runs a downloaded app from a random temporary path. A person who downloads by hand may well start it from there.

## Decision
- **Starting at login.** A setting, off until the user turns it on, through `SMAppService.mainApp`, so macOS lists Pairwise under Login Items and the user can also turn it off there. Taking the system's own state as the truth, the switch shows what macOS says. A failure is shown beside the switch. A debug build leaves it off, so that a build under development never starts by itself.
- **Moving.** A Release build that runs from outside Applications offers once to move there. On yes it copies itself to `/Applications`, with an older copy going to the Trash, starts the new copy and quits. On no it does not ask again. A failure is shown, and Pairwise goes on running where it is. The rule of when to offer is in `PairwiseCore`.
- A start at login is a normal start, so parked windows and pairs come back as ever (ADR 0053, 0054).

## Alternatives
- **On by default:** starting with the Mac is the user's choice, and not what a first run should decide.
- **A helper app as login item:** the older way, more parts for the same result on macOS 13 and later.
- **Only saying in the README to drag it to Applications:** people skip that, and the failures show up much later.
- **Asking at every start from elsewhere:** nagging; a person with a reason to keep it elsewhere has said so.

## Consequences
- Positive: one click for each, with the system's own switch as well.
- Negative / risks: copying into `/Applications` fails for a user without the right, which then shows an error. The copy on the disk image or in Downloads stays, to be deleted by the user.
- Changes now: `InstallPlace` in Core with tests, `LoginItem` and `AppMover` in the app, the setting with nl and de strings.
