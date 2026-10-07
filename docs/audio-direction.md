# Audio direction: "War Grimoire" in sound

The picture is an Edo woodblock print of a magic war: sumi ink, kozo paper, one vermilion seal,
indigo as the second block. The sound follows the same rules: **carved, dry, few colours, one
hot accent**. No synth pads, no glow, no lasers.

- **Ink and paper** are the effects: brush flicks, paper hiss, splats, a seal stamped onto paper.
- **Wood and skin** are the rhythm: hyoshigi clappers, woodblocks, shime-daiko and taiko.
- **Silk and bamboo** are the voice: shamisen (drive), koto (colour), shakuhachi (the singer).
- **Bronze** is the vermilion accent: one rin bowl, used only at moments that matter (the menu's
  red sun, shields, wave clear, game over).

Everything is in **D**. Menu, battle and game over use the **in (miyako-bushi) scale**
D Eb G A Bb. The boss turns darker into **iwato** (D Eb G Ab C), the scale with the tritone.

## Music (assets/audio/music, MP3 128 kbps, seamless loops)

| Cue | Use | Tempo / length | Loudness | What you should hear |
|---|---|---|---|---|
| `menu` | main menu and sub-menus | 60 bpm, 16 bars, 64.0 s loop | -18 LUFS | A low bowed D/A drone that breathes in and out; koto plucks dropped like ink drops every two bars; two long shakuhachi phrases that scoop up into each note, with long silences (*ma*) between; one deep odaiko stroke plus a ghost stroke and a rin bowl at bar 1 and bar 9 - the red sun. |
| `battle_base` | every fight, always on | 128 bpm, 40 bars, 75.0 s loop | -20.7 LUFS alone | Shamisen striking eighths (sixteenths in the last section) under a shakuhachi theme; koto off-beat dyads, then a koto answer melody in section B; a high sustained shakuhachi "cry" in section C; light skeleton of low taiko on 1 and 3, hyoshigi on 2 and 4, shime eighths. Form A-B-A-C-D. |
| `battle_war` | stacked on the base, sample-locked (AudioStreamSynchronized) | same grid | base+war -18.2 LUFS | The taiko ensemble: "don . . do-kon . doko don" on nagado-daiko, odaiko on the downbeat, shime sixteenths, chappa-like china crash every 8 bars, floor-tom rolls into odd bars; shinobue (piccolo) doubling the theme an octave up in A2 and the cry in C. |
| `boss` | waves 5, 10, 15... (mini-boss waves) | 140 bpm, 36 bars, 61.7 s loop | -17 LUFS | Iwato scale. Shamisen sixteenth tremolo, a hichiriki-like reed (GM shanai) on the melody, shakuhachi screaming up to D5/Eb5, taiko on every beat in the heavy sections, koto glissandi breaks, timpani rolls into each section. |
| `gameover` | once, when the run ends | 60 bpm, 11.5 s, not looped | -18 LUFS | Odaiko stroke and rin bowl, the bowed drone, shakuhachi falling A-G-Eb-D, a koto fifth, then a low D, fading out. |

**Escalation.** The war stem's level follows the wave: wave 1 silent, wave 2 -14 dB, 3 -9 dB,
4 -5 dB, 5 -2 dB, 6+ full. Between waves (preview, cards, intermission) it ducks a further
12 dB, so the drums swell when the fight starts and recede while you choose a card. Mini-boss
waves crossfade (1.2 s) to `boss`; clearing the wave crossfades back. Death crossfades to the
`gameover` sting.

**Loops.** Each loop is rendered three times back to back and the middle pass is cut out, so the
start already holds the previous pass's reverb tail. Decoded MP3 length equals the musical length
to the sample (`tools/audio/check_loops.py`), and the import files set `bpm`/`beat_count` so
Godot loops on the bar line.

## Sound effects (assets/audio/sfx, 16-bit mono WAV, synthesised)

Levels are normalised to a momentary-loudness target per role; true peaks stay at or below
-1.5 dBTP. Frequent sounds are quieter, rate-limited and pitch-jittered by the AudioManager.

| Event | File | Sound |
|---|---|---|
| Shot, normal mode | `shoot_normal` | brush flick rising, a silk tick under it |
| Shot, pierce | `shoot_pierce` | bamboo dart: hard thin click and a whistling streak |
| Shot, burst | `shoot_burst` | three paper flicks fanned out |
| Shot, ricochet | `shoot_ricochet` | woodblock "tok" with an FM rebound |
| Shot, hex | `shoot_hex` | low murmured curse: detuned FM on low Eb |
| Sword crescent (auto) | `sword` | wide brush stroke sweeping down, faint steel sing |
| Arcane bolt | `arcane` | high koto pluck and a fast rising brush |
| Frost nova | `nova` | skin thump, paper crackle, cold rin |
| Chain sigil | `chain` | carved ring stamped three times, D-G-A |
| Meteor rain | `meteor` | falling streak then a heavy taiko landing |
| Enemy hit | `hit` | paper punch, tiny and dull |
| Enemy death | `enemy_die` | ink splat and a low wood knock |
| Enemy shot | `enemy_shoot` | blowgun breath |
| Player hurt | `hurt` | taiko rim crack over a low body blow |
| Shield up / down / blocked | `shield_on` / `shield_off` / `shield_hit` | rin strike with an in-breath / short rin and out-breath / wood thock with a bright rin ping |
| Dash | `dash` | fast dry-brush drag upward |
| Bullet-mode switch | `mode_switch` | two small blocks clacking |
| Cards shown | `card_show` | three paper leaves fanned onto the page |
| Card / mitigation picked | `card_pick` | koto D-A-D rising and the seal pressed in |
| Wave start (also respawn) | `wave_start` | the seal-stamp thud: carved block on a drum |
| Wave clear | `wave_clear` | koto run up the in scale and a rin bowl |
| Mini-boss enters | `boss_appear` | two odaiko blows and a hyoshigi crack |
| Objective done / failed | `objective_success` / `objective_fail` | two koto notes and a rin / slack string falling a semitone and a dead thud |
| Player dies | `player_die` | the brush drops: long splat, one low drum |
| Any button hover / press | `ui_hover` / `ui_click` | fingertip on paper / small wood tap |
| Start a run | `ui_confirm` | the double hyoshigi clap that opens a performance |
| Potential bought / not enough | `ui_success` / `ui_fail` | koto, rin and a soft stamp / a muted low thud |

## Buses and settings

`AudioManager` creates the **Music** and **SFX** buses (both send to Master). The Master, Music
and SFX sliders in Settings drive those three bus volumes; values persist as before
(`settings.cfg`, plus localStorage on the web). Music keeps retrying playback each frame, so the
web build starts it on the first user gesture.

## Regenerating

```
python3 tools/audio/gen_sfx.py          # SFX (numpy/scipy)
python3 tools/audio/render.py           # music (fluidsynth, lame, mido)
python3 tools/audio/check_loops.py assets/audio/music/{menu,battle_base,battle_war,boss}.mp3
tools/audio/analyze.sh assets/audio/music/*.mp3 assets/audio/sfx/*.wav
```
