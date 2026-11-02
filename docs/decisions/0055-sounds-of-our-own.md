# 0055. Sounds of our own

- **Status:** Accepted
- **Date:** 2026-11-02
- **Milestone:** M3

## Context
ADR 0051 used two of the system's sounds for a join and a parting. The owner finds them not good enough, and wants the click of something that locks into place. macOS's sounds have no such click, and Apple's sounds may not be shipped with another app.

## Decision
- The app ships two recorded sounds, chosen by the owner by ear: `switch_004` for a join and `switch_001` for a parting, from [Interface Sounds by Kenney](https://opengameart.org/content/interface-sounds), under CC0, so they can be shipped and changed freely, and need no credit.
- They are converted to mono WAV, with the silence at the end taken off.
- This replaces only the choice of sounds in ADR 0051. The rest of it stands.

## Alternatives
- **Clicks made by a script:** tried first. Pure tones sounded electronic, resonance sounded like a drop in water, and without it they sounded like a creak.
- **Other system sounds:** none is a click.
- **A commercial sound library:** terms differ, and often restrict shipping a sound inside an app.

## Consequences
- Positive: a real click, with nobody else's rights involved.
- Negative / risks: the sounds can differ in loudness from other apps, as they follow the system's volume.
- Changes now: the two files, the window system.
