# Audio sources and licences

All music and sound effects in this folder were composed programmatically by AI (Claude) for
MagicEndless, as code in `tools/audio/`, and rendered offline with Vital / Serum 2 / the MS Basic
soundfont. No sample packs or recordings are used.

- **Music** (`music/*.mp3`): the notes are written in `tools/audio/compose.py`. The audiokit
  renderer turns them into audio, `tools/audio/finish_music.py` masters them, and they are encoded
  with LAME. Instruments:
  - **Vital** (Matt Tytel, GPL-3.0) presets: "Plucked String" (Vital Factory), "A Night in
    Kalyan" (Yuli Yolo pack), "Cinema Bells" (Billain pack).
  - **Serum 2** (Xfer Records) Factory presets: "WIND - Flute", "WIND - Pan Flute",
    "MAL - Hybrid Balafon", "PD - Bamboo Forest Reflections", "STR - Strings Ensemble - Elegy",
    "BL - Wudang Mountain".
  - **FluidSynth** with the **MuseScore "MS Basic" General MIDI soundfont** (`MS Basic.sf3`):
    acoustic bass, taiko, woodblock and the GM drum kit.
  - Effects are the built-in pedalboard (Spotify) reverb and filters.
- **Sound effects** (`sfx/*.wav`): made by `tools/audio/gen_sfx.py`. Each effect layers at least
  two sources, then envelopes, filters and normalises them. The sources are single preset hits
  from the instruments above (plus Vital "Ceramic" from the Databroth pack) and noise, drum and
  FM layers synthesised with numpy/scipy (`tools/audio/dsp.py`).

## Licence notes

- **Vital** is free software under the GPL-3.0. The GPL covers the synthesizer, not the audio
  made with it. The presets are Vital's bundled factory and pack presets.
- **Serum 2**: these are factory presets of a licensed copy, used to make original music.
- **MS Basic.sf3** is released under the **MIT License**. It ships with MuseScore 4 and is derived
  from MuseScore_General / FluidR3Mono / FluidR3 by Frank Wen, Michael Cowgill, S. Christian
  Collins, Ethan Winer and Michael Schorsch. Its full notice, which must accompany derivative
  works, is in `MS_Basic_License.md` next to this file.
- The rendered music and effects are released under the same licence as the game.
