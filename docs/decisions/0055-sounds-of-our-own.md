# 0055. Sounds of our own

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
ADR 0051 used two of the system's sounds for a join and a parting. The owner finds them not good enough, and wants the click of something that locks into place. macOS's sounds have no such click, and Apple's sounds may not be shipped with another app.

## Decision
- The app ships two sounds of its own, made by `tools/sounds/make_clicks.py`: a join is a light click and a firmer one, as a latch that goes home, and a parting is the other way round, higher and lighter. Both are under a tenth of a second.
- The script is in the repository, so the sounds can be changed by changing its numbers, and nobody else's rights are involved.
- This replaces only the choice of sounds in ADR 0051. The rest of it stands.

## Alternatives
- **A recording of a real click:** could sound more real, but needs a recording or a licence.
- **Other system sounds:** none is a click.

## Consequences
- Positive: a sound that says what happens, in the app's own hands.
- Negative / risks: a made sound can sound artificial, and only the ear can tell. The agent making it cannot hear it, so it takes the owner's judgement.
- Changes now: the script, the two files, the window system.
