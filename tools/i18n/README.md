# tools/i18n

Dutch and German translations for every String Catalog in the repository (ADR 0010). The translations are made in a chat and reviewed there before they land.

```sh
tools/build.sh build                    # extract the strings the code uses
python3 tools/i18n/translate.py sync    # add new English keys to the catalogs
python3 tools/i18n/translate.py status  # keys missing nl or de, per catalog
python3 tools/i18n/translate.py export  # → tools/i18n/_translation_input.json
# translate the JSON in a chat, save the reply as tools/i18n/_translation_output.json
python3 tools/i18n/translate.py import  # write nl and de into the catalogs
python3 tools/i18n/translate.py check   # missing translations, or equal to the English
```

- `tools/build.sh check` runs `check`, so a missing translation stops a commit.
- `import` fills only missing translations (`--force` overwrites) and rewrites the catalogs it changed in Xcode's style (`xcode_format.py`), so the diff shows only the translations.
- `check` fails on a translation that equals its English source, unless the key is in `identical-ok.txt`, grouped by why.
- Keys that must not be translated (the app name) carry `shouldTranslate: false`.
- The catalogs and the build targets whose strings they hold are listed in `CATALOGS` in `translate.py`; the glossary for both languages in `GLOSSARY`.
- The `_translation_*.json` working files are not committed.
