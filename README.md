# Magic Endless (异世界无尽战斗)

A 2D endless roguelite arena shooter made with Godot 4.5+. Play it on itch.io: https://kuthorx.itch.io/magicendless

## Languages

The game is available in **Chinese (中文)** and **English**.

- On first launch the language follows your system / browser language (Chinese → 中文, anything else → English).
- Switch at any time with the **Language / 语言** button on the main menu; the choice is saved locally.
- Translations live in `i18n/translations.csv` (`keys,zh,en`) and use Godot's built-in localization (`tr()` + `TranslationServer`).

## Audio

Music and sound effects were composed programmatically by AI (Claude) and rendered with
Vital / Serum 2 / the MS Basic soundfont. The score is in D, written in the Chinese yu
pentatonic mode, with a darker boss theme. Its voices are guzheng, dizi, xiao, a reed lead,
bianqing, strings, temple bell and taiko.

- Vital (GPL-3.0) presets: Plucked String (Factory), A Night in Kalyan (Yuli Yolo),
  Cinema Bells (Billain), Ceramic (Databroth).
- Serum 2 Factory presets: Flute, Pan Flute, Hybrid Balafon, Bamboo Forest Reflections,
  Strings Ensemble - Elegy, Wudang Mountain.
- MuseScore "MS Basic" GM soundfont (MIT): bass, taiko, woodblock and the drum kit.

Sources, licence notes and the MIT notice are in `assets/audio/LICENSE.md` and
`assets/audio/MS_Basic_License.md`. The cue sheet is in `docs/audio-direction.md`, and the
generators are in `tools/audio/`.
