# Audio sources and licences

All music and sound effects in this folder were made for MagicEndless from code in
`tools/audio/`. No sample packs and no AI generation; the only third-party material is the
soundfont below.

- **Sound effects** (`sfx/*.wav`): synthesised with numpy/scipy by `tools/audio/gen_sfx.py`.
  Same licence as the game code.
- **Music** (`music/*.mp3`): scored in `tools/audio/compose.py`, rendered by `tools/audio/render.py`
  with FluidSynth and the **MuseScore "MS Basic" General MIDI soundfont** (`MS Basic.sf3`, shipped
  with MuseScore 4; derived from MuseScore_General / FluidR3Mono / FluidR3 by Frank Wen, Michael
  Cowgill, S. Christian Collins, Ethan Winer and Michael Schorsch), released under the **MIT
  License**. Its full notice, which must accompany derivative works, is in
  `MS_Basic_License.md` next to this file. The rin bowl layer in the menu and game-over cues is
  synthesised by `tools/audio/dsp.py`.
