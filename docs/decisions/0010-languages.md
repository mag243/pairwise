# 0010. English, Dutch and German

- **Status:** Accepted
- **Date:** 2026-11-01
- **Milestone:** M0

## Context
The owner's apps are in English, Dutch and German, and all user-facing text goes through String Catalogs.

## Decision
The app supports **English** (source language), **Dutch** and **German**, follows the system language and falls back to English. A milestone that adds text is done only when every catalog has complete `nl` and `de` entries. Texts that must not be translated (the name "Pairwise") are marked `shouldTranslate: false`. an earlier project's translation tools (`tools/i18n/`) come over with the first milestone that adds text beyond the app's name.

## Alternatives
- **English only:** less work, but not what the owner wants.

## Consequences
- The project lists `en`, `nl` and `de` as known regions.
- Catalogs in `PairwiseCore` and `PairwiseUI` are added with their first text.
