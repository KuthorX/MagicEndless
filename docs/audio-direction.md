# Audio direction: an ink-wash grimoire in sound

The picture is sumi ink on paper with one vermilion seal. The sound follows the same rules:
**ink and paper, wood and bronze, silk and bamboo, with few colours and one hot accent**.
Melodic voices: guzheng (silk), dizi and xiao (bamboo), a reedy suona-like lead. Rhythm: bianqing
(stone/wood mallets), taiko, woodblock. Bronze accent: the temple bell, used at moments that matter.

Everything is in **D**. Menu, battle and game over use the Chinese **yu** pentatonic mode
(D F G A C). The boss darkens it with Eb and Bb and the tritone G#, and its last bar turns to A
with C# so it leans back into the loop.

The music and SFX were composed programmatically by AI (Claude), as code in `tools/audio/`. They
were rendered offline with Vital, Serum 2 and the MS Basic soundfont through the shared audiokit
renderer (`/tmp/audiokit/render.py`). Sources and licences are listed in `assets/audio/LICENSE.md`.

## Music (assets/audio/music, Ogg Vorbis ~110 kbps, seamless loops)

| Cue | Use | Tempo / length | Loudness | Parts (preset) |
|---|---|---|---|---|
| `menu` | main menu and sub-menus | 60 bpm, 16 bars, 64.0 s loop | -18 LUFS | Pad: Serum 2 "Bamboo Forest Reflections", 2-bar chords Dm7-F6-Csus2-Dm-G7sus-F6-Csus2-A7sus4. Guzheng ink-drop plucks: Vital "Plucked String". Two xiao phrases with long rests: Serum 2 "Pan Flute". The red sun at bars 1 and 9: a taiko stroke with a ghost stroke (GM 116) and the temple bell (Serum 2 "Wudang Mountain"). |
| `battle_base` | every fight, always on | 128 bpm, 40 bars, 75.0 s loop | -19.5 LUFS alone | Form A-B-A-C-D. Bianqing ostinato in eighths, sixteenths in D: Serum 2 "Hybrid Balafon". GM acoustic bass. Guzheng off-beat dyads, the answer melody in B and rolling arpeggios in C. The dizi theme in A and D: Serum 2 "Flute". The reed "cry" in C plus a low doubling in D: Vital "A Night in Kalyan". Kick, woodblock and shaker skeleton from the GM kit. |
| `battle_war` | stacked on the base, sample-locked (AudioStreamSynchronized) | same grid | base+war -17.5 LUFS | Floor-tom pattern "don . . do-kon . doko don", kick on 1 and 3, side-stick eighths (sixteenths in C and D), tom rolls every 4 bars, china every 8 (GM kit). Taiko on alternate bars (GM 116). String swells: Serum 2 "Strings Ensemble - Elegy". A high xiao doubling the theme in the second A and in D, and the cry in C. |
| `boss` | waves 5, 10, 15... (mini-boss waves) | 140 bpm, 36 bars, 61.7 s loop | -17.5 LUFS | Intro-A-B-C-D. Bianqing sixteenth tremolo, driving bass eighths, the reed lead (Kalyan) climbing to Bb5 in C. Strings power chords. The low gong at each section start: Vital "Cinema Bells". Guzheng glissandi into each section. Kick on every beat with snare backbeat in B and D. Taiko. |
| `gameover` | once, when the run ends | 60 bpm, 11.5 s, not looped | -18 LUFS | Taiko stroke and temple bell, a Dm7 pad, the xiao falling A-G-F-D, a guzheng fifth, then a low D, fading out. |

**Escalation.** The war stem's level follows the wave: wave 1 silent, wave 2 -14 dB, 3 -9 dB,
4 -5 dB, 5 -2 dB, 6+ full. Between waves (preview, cards, intermission) it ducks a further
12 dB, so the drums swell when the fight starts and recede while you choose a card. Mini-boss
waves crossfade (1.2 s) to `boss`, and clearing the wave crossfades back. Death crossfades to the
`gameover` sting.

**Loops.** Each cue is rendered once, then the renderer's loop option folds everything that rings
past the loop end (release and reverb tails) back onto the loop start. The seam therefore sounds
like the next pass. The decoded Ogg Vorbis length equals the musical length to the sample
(`tools/audio/check_loops.py`), and the import files set `bpm`/`beat_count` so Godot loops on the
bar line.

## Sound effects (assets/audio/sfx, 16-bit mono WAV; effects over 0.5 s as mono Ogg Vorbis; layered preset hits + synthesis)

Each effect layers single preset hits with synthesised noise, drum and FM layers. The hits are
guzheng, temple bell, gong, ceramic tick, bianqing, xiao, taiko and woodblock, rendered once into
`tools/audio/build/stems_sfx_hits`. Levels are normalised to a momentary-loudness target per role:
-16 for the big moments (wave start, boss, hurt, death), about -22 for shots and -30 for hover.
True peaks stay at or below -1.5 dBTP. Frequent sounds are quieter, rate-limited and pitch-jittered by the AudioManager.

| Event | File | Sound |
|---|---|---|
| Shot, normal mode | `shoot_normal` | brush flick rising, a high guzheng tick under it |
| Shot, pierce | `shoot_pierce` | bamboo dart: ceramic click and a whistling streak |
| Shot, burst | `shoot_burst` | three paper flicks fanned out |
| Shot, ricochet | `shoot_ricochet` | bianqing "tok" with an FM rebound |
| Shot, hex | `shoot_hex` | low murmured curse: a muted low guzheng Eb under detuned FM |
| Sword crescent (auto) | `sword` | wide brush stroke sweeping down, faint bell sing |
| Arcane bolt | `arcane` | high guzheng pluck and a fast rising brush |
| Frost nova | `nova` | taiko thump, paper crackle, cold temple bell |
| Chain sigil | `chain` | bianqing and guzheng struck three times, D-G-A |
| Meteor rain | `meteor` | falling streak then a heavy taiko landing |
| Enemy hit | `hit` | paper punch, tiny and dull |
| Enemy death | `enemy_die` | ink splat and a low bianqing knock |
| Enemy shot | `enemy_shoot` | blowgun breath (xiao chiff) |
| Player hurt | `hurt` | woodblock crack over a taiko body blow |
| Shield up / down / blocked | `shield_on` / `shield_off` / `shield_hit` | bell strike with an in-breath / short bell and out-breath / bianqing thock with a bright bell ping |
| Dash | `dash` | fast dry-brush drag upward |
| Bullet-mode switch | `mode_switch` | two small blocks clacking |
| Cards shown | `card_show` | three paper leaves fanned onto the page |
| Card / mitigation picked | `card_pick` | guzheng D-A-D rising and the seal pressed in (taiko) |
| Wave start (also respawn) | `wave_start` | the seal-stamp thud: low taiko and a carved block |
| Wave clear | `wave_clear` | guzheng run up the yu scale and the temple bell |
| Mini-boss enters | `boss_appear` | two taiko blows, the low gong, a woodblock double crack |
| Objective done / failed | `objective_success` / `objective_fail` | two guzheng notes and a bell / slack string falling a semitone and a dead taiko thud |
| Player dies | `player_die` | the brush drops: long splat, one low taiko and the gong |
| Any button hover / press | `ui_hover` / `ui_click` | fingertip on paper with a ceramic tick / small bianqing tap |
| Start a run | `ui_confirm` | the double woodblock clap that opens a performance |
| Potential bought / not enough | `ui_success` / `ui_fail` | guzheng, bell and a soft taiko / a muted low taiko and a slack string |

## Buses and settings

`AudioManager` creates the **Music** and **SFX** buses (both send to Master). The Master, Music
and SFX sliders in Settings drive those three bus volumes; values persist as before
(`settings.cfg`, plus localStorage on the web). Music keeps retrying playback each frame, so the
web build starts it on the first user gesture.

## Regenerating

Everything renders offline and never plays audio. It needs the audiokit toolchain in
`/tmp/audiokit`, and every render takes the shared lock.

```
tools/audio/render_all.sh                    # compose.py + SFX hit list -> render every spec
arch -arm64 /tmp/audiokit/venv/bin/python tools/audio/remix.py   # optional: new gains, no re-render
arch -arm64 /tmp/audiokit/venv/bin/python tools/audio/finish_music.py   # balance, master, Ogg Vorbis
arch -arm64 /tmp/audiokit/venv/bin/python tools/audio/gen_sfx.py build  # layer the SFX
python3 tools/audio/check_loops.py assets/audio/music/{menu,battle_base,battle_war,boss}.ogg
tools/audio/analyze.sh assets/audio/music/*.ogg assets/audio/sfx/*.ogg assets/audio/sfx/*.wav
```
