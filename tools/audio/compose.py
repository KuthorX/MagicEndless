#!/usr/bin/env python3
"""The MagicEndless score, written as code: MIDI files plus /tmp/audiokit render specs.

Key: D. Menu, battle and game over use the Chinese **yu** pentatonic mode (D F G A C); the boss
darkens it with Eb, Bb and the tritone G#. Instruments (all rendered offline by audiokit):
  guzheng  Vital "Plucked String"            dizi   Serum 2 "WIND - Flute"
  xiao     Serum 2 "WIND - Pan Flute"         suona  Vital "A Night in Kalyan" (reedy lead)
  bianqing Serum 2 "MAL - Hybrid Balafon"     pad    Serum 2 "PD - Bamboo Forest Reflections"
  strings  Serum 2 "STR - Strings Ensemble - Elegy"
  bell     Serum 2 "BL - Wudang Mountain"     gong   Vital "Cinema Bells" (+24, it plays 2 oct low)
  bass / taiko / drum kit: fluidsynth + MuseScore "MS Basic" GM (programs 32, 116, kit)

Cues (tempo/length match the Godot .import files, so the loops stay on the bar line):
  menu         60 bpm, 16 bars, 64.0 s loop      battle_base / battle_war 128 bpm, 40 bars, 75.0 s
  boss        140 bpm, 36 bars, 61.714 s loop    gameover 60 bpm, 11.5 s one-shot

Run with the audiokit venv:  arch -arm64 /tmp/audiokit/venv/bin/python tools/audio/compose.py
Writes tools/audio/build/<cue>.mid and <cue>.json (render with tools/audio/render_all.sh).
"""
import json
import os
import sys

import numpy as np

sys.path.insert(0, "/tmp/audiokit")
import midi_io  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
BUILD = os.path.join(HERE, "build")

VITAL = os.path.expanduser("~/Music/Vital")
S2 = "/Library/Audio/Presets/Xfer Records/Serum 2 Presets/Presets/Factory"


def _find_vital(name):
    for root, _, files in os.walk(VITAL):
        if name + ".vital" in files:
            return os.path.join(root, name + ".vital")
    raise FileNotFoundError(name)


GUZHENG = {"type": "vital", "preset": _find_vital("Plucked String")}
SUONA = {"type": "vital", "preset": _find_vital("A Night in Kalyan")}
GONG = {"type": "vital", "preset": _find_vital("Cinema Bells")}
DIZI = {"type": "serum2", "preset": f"{S2}/Woodwind/WIND - Flute.SerumPreset"}
XIAO = {"type": "serum2", "preset": f"{S2}/Woodwind/WIND - Pan Flute.SerumPreset"}
BIANQING = {"type": "serum2", "preset": f"{S2}/Mallet/MAL - Hybrid Balafon.SerumPreset"}
PAD = {"type": "serum2", "preset": f"{S2}/Pad/PD - Bamboo Forest Reflections.SerumPreset"}
STRINGS = {"type": "serum2", "preset": f"{S2}/String/STR - Strings Ensemble - Elegy.SerumPreset"}
BELL = {"type": "serum2", "preset": f"{S2}/Bell/BL - Wudang Mountain.SerumPreset"}
BASS = {"type": "fluidsynth", "program": 32, "gain": 0.6}
TAIKO = {"type": "fluidsynth", "program": 116, "gain": 0.6}
KIT = {"type": "fluidsynth", "program": 0, "gain": 0.6}

# GM kit keys (channel 10)
KICK, SIDE, SNARE, FLOOR_LO, FLOOR_HI, TOM_LO, TOM_HI = 36, 37, 38, 41, 43, 45, 50
CHINA, SHAKER, WOOD_HI, WOOD_LO = 52, 82, 76, 77

N = {"C": 0, "C#": 1, "D": 2, "Eb": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "Bb": 10, "B": 11}
YU = [2, 5, 7, 9, 0]  # D F G A C


def p(name, octave):
    """Note name + octave -> MIDI pitch (C4 = 60)."""
    return 12 * (octave + 1) + N[name]


def rev(room=0.7, wet=0.22, dry=0.85, width=1.0):
    return {"type": "Reverb", "room_size": room, "wet_level": wet, "dry_level": dry, "width": width}


def hp(f):
    return {"type": "HighpassFilter", "cutoff_frequency_hz": f}


def lp(f):
    return {"type": "LowpassFilter", "cutoff_frequency_hz": f}


class Part:
    """One instrument line: notes in beats, deterministic humanising (never before beat 0)."""

    def __init__(self, seed, ch=0, swing=0.008, spread=6):
        self.notes, self.ch = [], ch
        self.r = np.random.default_rng(seed)
        self.swing, self.spread = swing, spread

    def n(self, beat, dur, pitch, vel=90):
        t = beat + (float(self.r.uniform(-self.swing, self.swing)) if beat > 0.05 else 0.0)
        v = int(np.clip(vel + self.r.integers(-self.spread, self.spread + 1), 1, 127))
        self.notes.append((round(t, 4), dur, int(pitch), v, self.ch))

    def line(self, beat, seq, vel=90, legato=0.96, octave=0):
        """seq: [(pitch or None, beats), ...] written back to back."""
        for pitch, d in seq:
            if pitch is not None:
                self.n(beat, d * legato, pitch + 12 * octave, vel)
            beat += d
        return beat

    def chord(self, beat, dur, pitches, vel=80):
        for q in pitches:
            self.n(beat, dur, q, vel)


def write(cue, bpm, tracks, spec_extra):
    """tracks: [(name, Part, instrument, gain_db, pan, fx, transpose)]."""
    os.makedirs(BUILD, exist_ok=True)
    mid = os.path.join(BUILD, cue + ".mid")
    midi_io.write_midi(mid, [t[1].notes for t in tracks], bpm=bpm)
    spec = {"out": os.path.join(BUILD, cue + ".wav"), "lufs": -18, "ceiling_dbtp": -1,
            "subtype": "FLOAT", "png": True, "stems_dir": os.path.join(BUILD, "stems_" + cue), "tracks": []}
    spec.update(spec_extra)
    for i, (name, _, inst, gain, pan, fx, tr) in enumerate(tracks):
        spec["tracks"].append({"name": name, "midi": mid, "track": i, "instrument": inst,
                               "gain_db": gain, "pan": pan, "fx": fx, "transpose": tr})
    with open(os.path.join(BUILD, cue + ".json"), "w") as f:
        json.dump(spec, f, indent=1)
    print(f"{cue:12s} {sum(len(t[1].notes) for t in tracks):5d} notes  {len(tracks)} tracks")


# ------------------------------------------------------------------------------------- menu
MENU_BPM, MENU_BEATS = 60, 64
MENU_CHORDS = [  # two bars each
    [p("D", 2), p("A", 2), p("C", 3), p("F", 3), p("A", 3)],          # Dm7
    [p("F", 2), p("C", 3), p("D", 3), p("A", 3)],                      # F6
    [p("C", 2), p("G", 2), p("D", 3), p("G", 3)],                      # Csus2
    [p("D", 2), p("A", 2), p("D", 3), p("F", 3), p("G", 3)],          # Dm(add4)
    [p("G", 2), p("D", 3), p("C", 3) + 12, p("F", 3)],                # G sus4/7
    [p("F", 2), p("C", 3), p("A", 3), p("D", 4)],                      # F6
    [p("C", 2), p("G", 2), p("D", 3), p("G", 3)],                      # Csus2
    [p("A", 1), p("E", 2), p("D", 3), p("G", 3)],                      # A7sus4 -> back to Dm
]
XIAO_1 = [(p("A", 4), 2), (p("C", 5), 1), (p("D", 5), 3), (p("C", 5), 1.5), (p("A", 4), .5), (p("G", 4), 2),
          (p("A", 4), 4), (None, 2), (p("F", 4), 1), (p("G", 4), 1), (p("A", 4), 2), (p("D", 4), 4)]
XIAO_2 = [(p("D", 5), 2), (p("F", 5), 2), (p("G", 5), 3), (p("F", 5), 1), (p("D", 5), 2), (p("C", 5), 2),
          (p("A", 4), 4), (None, 2), (p("C", 5), 1), (p("A", 4), 1), (p("G", 4), 2), (p("A", 4), 2)]
INK_DROPS = [  # guzheng: (beat in bar, pitch) for each bar, a few plucks like ink drops
    [(0, p("D", 4)), (1.5, p("A", 4)), (2, p("D", 5)), (3.5, p("C", 5))],
    [(0.5, p("F", 4)), (2, p("A", 4)), (3, p("G", 4))],
    [(0, p("C", 4)), (0, p("F", 4)), (1.5, p("A", 4)), (2.5, p("C", 5)), (3, p("D", 5))],
    [(1, p("A", 4)), (2.5, p("G", 4))],
    [(0, p("C", 4)), (1, p("G", 4)), (1.5, p("A", 4)), (2, p("D", 5))],
    [(0.5, p("C", 5)), (2, p("G", 4))],
    [(0, p("D", 4)), (0.75, p("F", 4)), (1.5, p("A", 4)), (3, p("G", 4)), (3.5, p("F", 4))],
    [(1, p("D", 4)), (2, p("A", 3))],
]


def menu():
    pad, zheng, xiao, bell, taiko = Part(1), Part(2), Part(3), Part(4), Part(5)
    for k, ch in enumerate(MENU_CHORDS):
        pad.chord(k * 8, 7.9, ch, 70)
    for bar in range(16):
        drops = INK_DROPS[bar % 8]
        for b, q in drops:
            zheng.n(bar * 4 + b, 1.8, q + (12 if bar >= 8 and q < p("A", 4) else 0), 72)
    xiao.line(8, XIAO_1, 84, legato=0.98)
    xiao.line(40, XIAO_2, 84, legato=0.98)
    for b in (0, 32):  # the red sun: one deep drum, a ghost stroke and the temple bell
        taiko.n(b, 2, p("D", 2), 112)
        taiko.n(b + 0.75, 1, p("D", 2), 48)
        bell.n(b, 4, p("D", 4) if b == 0 else p("A", 3), 70)
    taiko.n(16, 2, p("A", 1), 64)
    taiko.n(48, 2, p("A", 1), 64)
    write("menu", MENU_BPM, [
        ("pad", pad, PAD, -3, 0, [hp(60), rev(0.85, 0.3, 0.8)], 0),
        ("guzheng", zheng, GUZHENG, -7, -0.3, [rev(0.8, 0.3, 0.8)], 0),
        ("xiao", xiao, XIAO, 0, 0.25, [rev(0.85, 0.3, 0.8)], 0),
        ("bell", bell, BELL, -4, 0.1, [rev(0.9, 0.3, 0.8)], 0),
        ("taiko", taiko, TAIKO, 1, 0, [rev(0.75, 0.2, 0.9)], 0),
    ], {"loop": MENU_BEATS * 60 / MENU_BPM, "tail": 6, "lufs": -18})


# ----------------------------------------------------------------------------------- battle
BATTLE_BPM, BATTLE_BEATS = 128, 160
_A = ["D", "D", "C", "C", "F", "F", "G", "A"]
_B = ["F", "F", "G", "G", "D", "D", "C", "A"]
_C = ["G", "G", "F", "F", "C", "C", "A", "A"]
BATTLE_FORM = [("A", _A), ("B", _B), ("A", _A), ("C", _C), ("D", _A)]
FIFTH = {"D": "A", "C": "G", "F": "C", "G": "D", "A": "E", "Eb": "Bb", "Bb": "F", "G#": "D#"}
UPPER = {  # upper chord tones for dyads/strings (pentatonic voicings, no thirds on C/G)
    "D": ["A", "D", "F"], "C": ["G", "C", "D"], "F": ["A", "C", "F"], "G": ["C", "D", "G"],
    "A": ["E", "A", "C"],
}
THEME = [  # dizi, 8 bars over D D C C F F G A
    [("A", 4, 1), ("D", 5, .5), ("C", 5, .5), ("A", 4, 1), ("G", 4, 1)],
    [("A", 4, 3), ("F", 4, .5), ("G", 4, .5)],
    [("G", 4, 1), ("C", 5, 1), ("D", 5, 1), ("C", 5, .5), ("A", 4, .5)],
    [("G", 4, 2), ("D", 4, .5), ("F", 4, .5), ("G", 4, 1)],
    [("A", 4, 1), ("C", 5, 1), ("F", 5, 1.5), ("D", 5, .5)],
    [("C", 5, 2), ("A", 4, 1), ("C", 5, 1)],
    [("D", 5, 1.5), ("C", 5, .5), ("A", 4, 1), ("G", 4, 1)],
    [("A", 4, 4)],
]
ANSWER = [  # guzheng lead in B, over F F G G D D C A
    [("C", 5, .5), ("A", 4, .5), ("C", 5, .5), ("D", 5, .5), ("F", 5, 1), ("D", 5, 1)],
    [("C", 5, .5), ("D", 5, .5), ("C", 5, .5), ("A", 4, .5), ("F", 4, 2)],
    [("G", 4, .5), ("C", 5, .5), ("D", 5, .5), ("F", 5, .5), ("G", 5, 1), ("F", 5, .5), ("D", 5, .5)],
    [("C", 5, 2), ("D", 5, 1), ("C", 5, 1)],
    [("A", 4, .5), ("D", 5, .5), ("F", 5, .5), ("A", 5, .5), ("G", 5, 1), ("F", 5, 1)],
    [("D", 5, 3), ("C", 5, .5), ("D", 5, .5)],
    [("G", 4, .5), ("C", 5, .5), ("D", 5, .5), ("G", 5, .5), ("F", 5, 1), ("D", 5, 1)],
    [("C", 5, 1), ("A", 4, 1), ("E", 5, 1), ("A", 4, 1)],
]
CRY = [  # suona-like reed, long notes over G G F F C C A A
    [("D", 5, 4)], [("F", 5, 2), ("D", 5, 2)], [("C", 5, 4)], [("A", 4, 3), ("C", 5, 1)],
    [("G", 4, 4)], [("D", 5, 2), ("C", 5, 2)], [("A", 4, 4)], [("A", 4, 2), ("G", 4, 1), ("A", 4, 1)],
]


def _bars(seq_bars, transpose=0):
    return [(p(n, o) + transpose, d) for bar in seq_bars for n, o, d in bar]


def battle_base():
    bian, bass, zheng, dizi, suona, perc = Part(11), Part(12), Part(13), Part(14), Part(15), Part(16, ch=9)
    for s, (sec, roots) in enumerate(BATTLE_FORM):
        for i, r in enumerate(roots):
            b0 = (s * 8 + i) * 4
            root3 = p(r, 3) if r in ("C", "D", "F") else p(r, 2)
            fifth = root3 + 7
            # bianqing ostinato: eighths (sixteenths in the climax)
            pat = [root3, fifth, root3 + 12, fifth] * 2
            if sec == "D":
                for k in range(16):
                    bian.n(b0 + k * 0.25, 0.22, pat[k % 8] + (12 if k % 4 == 2 else 0), 92 if k % 4 == 0 else 70)
            else:
                for k, q in enumerate(pat):
                    bian.n(b0 + k * 0.5, 0.45, q, 90 if k % 2 == 0 else 68)
            # bass: root on 1, the and-of-2, the fifth on 4
            br = p(r, 2)
            bass.n(b0, 1.4, br, 100)
            bass.n(b0 + 1.5, 0.9, br, 84)
            bass.n(b0 + 3, 0.9, br + 7, 88)
            # guzheng: off-beat dyads in A / D, rolling arpeggios in C
            up = [p(n, 4) for n in UPPER[r]]
            if sec in ("A", "D"):
                for ob in (1.5, 3.5):
                    zheng.chord(b0 + ob, 0.4, up[:2], 70)
            elif sec == "C":
                for k, q in enumerate([up[0] - 12, up[1] - 12, up[0], up[2], up[1], up[0], up[2], up[1]]):
                    zheng.n(b0 + k * 0.5, 0.9, q, 66)
            # percussion skeleton
            for bt in (0, 2):
                perc.n(b0 + bt, 0.2, KICK, 92)
            for bt in (1, 3):
                perc.n(b0 + bt, 0.1, WOOD_HI, 80)
            for k in range(8):
                perc.n(b0 + k * 0.5, 0.1, SHAKER, 46 if k % 2 else 58)
        s0 = s * 32
        if sec == "A":
            dizi.line(s0, _bars(THEME), 92)
        elif sec == "B":
            zheng.line(s0, _bars(ANSWER), 96, legato=1.6)
        elif sec == "C":
            suona.line(s0, _bars(CRY), 86, legato=0.99)
        else:
            dizi.line(s0, _bars(THEME), 98)
            suona.line(s0, _bars(THEME, -12), 70)
            # gliss up the yu scale into the loop point
            run = [p(n, o) for o in (4, 5) for n in ("D", "F", "G", "A", "C")]
            for k, q in enumerate(run):
                zheng.n(s0 + 30 + k * 0.2, 0.6, q, 60 + 4 * k)
    write("battle_base", BATTLE_BPM, [
        ("bianqing", bian, BIANQING, -2, -0.2, [hp(90), rev(0.6, 0.15, 0.9)], 0),
        ("bass", bass, BASS, 6, 0, [lp(2500)], 0),
        ("guzheng", zheng, GUZHENG, -10, 0.3, [rev(0.7, 0.22, 0.85)], 0),
        ("dizi", dizi, DIZI, -1, -0.05, [rev(0.75, 0.22, 0.85)], 0),
        ("suona", suona, SUONA, -1, 0.1, [rev(0.75, 0.22, 0.85)], 0),
        ("perc", perc, KIT, 1, 0, [rev(0.5, 0.12, 0.9)], 0),
    ], {"loop": BATTLE_BEATS * 60 / BATTLE_BPM, "tail": 4, "lufs": -19.5})


def battle_war():
    drums, taiko, strings, xiao = Part(21, ch=9), Part(22), Part(23), Part(24)
    for s, (sec, roots) in enumerate(BATTLE_FORM):
        for i, r in enumerate(roots):
            bar = s * 8 + i
            b0 = bar * 4
            # "don . . do-kon . doko don" on the floor toms, kick on 1 and 3
            for bt, key, v in ((0, FLOOR_LO, 112), (1.5, FLOOR_HI, 90), (2, FLOOR_LO, 104),
                               (2.75, FLOOR_HI, 80), (3, FLOOR_LO, 96), (3.5, FLOOR_LO, 88)):
                drums.n(b0 + bt, 0.2, key, v)
            drums.n(b0, 0.2, KICK, 110)
            drums.n(b0 + 2, 0.2, KICK, 96)
            for k in range(16 if sec in ("C", "D") else 8):
                step = 0.25 if sec in ("C", "D") else 0.5
                drums.n(b0 + k * step, 0.1, SIDE, 64 if k % 2 else 78)
            if i % 4 == 3:  # roll into the next phrase
                for k in range(8):
                    drums.n(b0 + 2 + k * 0.25, 0.15, TOM_HI if k < 4 else TOM_LO, 70 + 5 * k)
            if i == 0:
                drums.n(b0, 1.5, CHINA, 96)
            if i % 2 == 0:
                taiko.n(b0, 1.5, p(r, 2) if r not in ("A", "G") else p(r, 1), 116)
                taiko.n(b0 + 2.5, 1.0, p(r, 2) if r not in ("A", "G") else p(r, 1), 84)
            if i % 2 == 0:  # strings: one swelling chord per two bars
                up = sorted({p(n, 4) for n in UPPER[r]} | {p(r, 3)})
                strings.chord(b0, 7.8, up, 74)
        s0 = s * 32
        if s == 2 or sec == "D":
            xiao.line(s0, _bars(THEME, 12), 78)
        elif sec == "C":
            xiao.line(s0, _bars(CRY, 12), 70)
    write("battle_war", BATTLE_BPM, [
        ("drums", drums, KIT, 2, 0, [rev(0.6, 0.15, 0.9)], 0),
        ("taiko", taiko, TAIKO, 5, 0, [rev(0.7, 0.18, 0.9)], 0),
        ("strings", strings, STRINGS, -9, 0, [hp(120), rev(0.8, 0.25, 0.85)], 0),
        ("xiao_hi", xiao, XIAO, -8, 0.3, [rev(0.8, 0.25, 0.85)], 0),
    ], {"loop": BATTLE_BEATS * 60 / BATTLE_BPM, "tail": 4, "lufs": -19.5})


# ------------------------------------------------------------------------------------- boss
BOSS_BPM, BOSS_BEATS = 140, 144
_BI = ["D"] * 4
_BA = ["D", "D", "Eb", "D", "D", "D", "C", "Bb"]
_BB = ["G", "G", "F", "F", "Eb", "Eb", "D", "D"]
_BC = ["D", "D", "Eb", "Eb", "G#", "G#", "A", "A"]
_BD = ["D", "D", "Eb", "D", "D", "D", "C", "A"]
BOSS_FORM = [("I", _BI), ("A", _BA), ("B", _BB), ("C", _BC), ("D", _BD)]
REED = [
    [("D", 5, 1.5), ("Eb", 5, .5), ("D", 5, 1), ("A", 4, 1)],
    [("C", 5, 1), ("A", 4, 1), ("G#", 4, 1), ("A", 4, 1)],
    [("Bb", 4, 1.5), ("C", 5, .5), ("Eb", 5, 2)],
    [("D", 5, 4)],
    [("F", 5, 1.5), ("Eb", 5, .5), ("D", 5, 1), ("C", 5, 1)],
    [("D", 5, 2), ("A", 4, 2)],
    [("G", 4, 1), ("A", 4, 1), ("C", 5, 1), ("Eb", 5, 1)],
    [("D", 5, 3), ("C", 5, 1)],
]
SCREAM = [
    [("A", 5, 4)], [("G#", 5, 2), ("A", 5, 2)], [("Bb", 5, 3), ("A", 5, 1)], [("G", 5, 4)],
    [("G#", 5, 4)], [("F", 5, 2), ("D", 5, 2)], [("E", 5, 4)], [("A", 4, 2), ("C#", 5, 2)],
]


def _boss_root(r):
    q = p(r, 2)
    return q + 12 if q < p("C#", 2) else q


def boss():
    bian, bass, suona, strings, gong, zheng, drums, taiko = (Part(31), Part(32), Part(33), Part(34), Part(35),
                                                             Part(36), Part(37, ch=9), Part(38))
    bar = 0
    for sec, roots in BOSS_FORM:
        for i, r in enumerate(roots):
            b0 = bar * 4
            root = _boss_root(r)
            fifth = root + 7
            for k in range(16):  # bianqing sixteenth tremolo
                q = [root + 12, fifth + 12, root + 24, fifth + 12][k % 4]
                bian.n(b0 + k * 0.25, 0.2, q, 90 if k % 4 == 0 else 66)
            for k in range(8):  # driving bass eighths
                bass.n(b0 + k * 0.5, 0.42, root if k != 6 else fifth, 100 if k % 2 == 0 else 82)
            if i % 2 == 0 and sec != "I":
                strings.chord(b0, 7.8, [root + 12, fifth + 12, root + 24], 80)
            heavy = sec in ("B", "D")
            for bt in range(4):
                if heavy or bt % 2 == 0:
                    drums.n(b0 + bt, 0.2, KICK, 112 if bt == 0 else 96)
                if heavy and bt % 2 == 1:
                    drums.n(b0 + bt, 0.2, SNARE, 100)
            for bt, key in ((0.5, FLOOR_HI), (1.5, FLOOR_LO), (2.5, FLOOR_HI), (3.25, FLOOR_LO), (3.5, FLOOR_LO)):
                drums.n(b0 + bt, 0.2, key, 84)
            if i == 0:
                drums.n(b0, 1.5, CHINA, 104)
                gong.n(b0, 6, root + 24 + 12, 92)  # Cinema Bells sounds two octaves down
            if i == len(roots) - 1:  # guzheng glissando into the next section
                run = [p(n, o) for o in (4, 5) for n in ("D", "Eb", "G", "A", "C")]
                for k, q in enumerate(run):
                    zheng.n(b0 + 2 + k * 0.2, 0.5, q, 62 + 4 * k)
            taiko.n(b0, 1.5, root - 12 if root - 12 >= p("A", 1) else root, 120 if heavy else 100)
            if heavy:
                taiko.n(b0 + 2, 1.0, root - 12 if root - 12 >= p("A", 1) else root, 96)
            bar += 1
        s0 = (bar - len(roots)) * 4
        if sec == "A":
            suona.line(s0, _bars(REED), 94)
        elif sec == "C":
            suona.line(s0, _bars(SCREAM), 100)
        elif sec == "D":
            seq = _bars(REED[:7]) + [(p("C#", 5), 2), (p("E", 5), 2)]
            suona.line(s0, seq, 100)
        elif sec == "B":
            for k, r in enumerate(roots):  # guzheng tremolo motif answering the strings
                b0 = s0 + k * 4
                q = _boss_root(r) + 24
                for j in range(8):
                    zheng.n(b0 + j * 0.5, 0.45, q + (7 if j in (2, 6) else 0) + (3 if j == 4 else 0), 76)
    write("boss", BOSS_BPM, [
        ("bianqing", bian, BIANQING, -3, -0.25, [hp(110), rev(0.6, 0.15, 0.9)], 0),
        ("bass", bass, BASS, 4, 0, [lp(2200)], 0),
        ("suona", suona, SUONA, 0, 0.05, [rev(0.75, 0.22, 0.85)], 0),
        ("strings", strings, STRINGS, -8.5, 0, [hp(120), rev(0.8, 0.25, 0.85)], 0),
        ("gong", gong, GONG, -6, 0, [rev(0.85, 0.25, 0.85)], 0),
        ("guzheng", zheng, GUZHENG, -13, 0.3, [rev(0.75, 0.22, 0.85)], 0),
        ("drums", drums, KIT, 3, 0, [rev(0.55, 0.12, 0.9)], 0),
        ("taiko", taiko, TAIKO, 5, 0, [rev(0.7, 0.18, 0.9)], 0),
    ], {"loop": BOSS_BEATS * 60 / BOSS_BPM, "tail": 4, "lufs": -17.5})


# --------------------------------------------------------------------------------- gameover
def gameover():
    pad, xiao, zheng, bell, taiko = Part(41), Part(42), Part(43), Part(44), Part(45)
    taiko.n(0, 3, p("D", 2), 118)
    bell.n(0, 6, p("D", 4), 76)
    pad.chord(0, 8.5, [p("D", 2), p("A", 2), p("F", 3), p("C", 4)], 66)
    xiao.line(1.5, [(p("A", 4), 1.5), (p("G", 4), 1), (p("F", 4), 1), (p("D", 4), 4)], 80, legato=0.98)
    zheng.chord(5, 3, [p("D", 3), p("A", 3)], 74)
    zheng.n(7.5, 3, p("D", 2), 82)
    write("gameover", 60, [
        ("pad", pad, PAD, -2, 0, [hp(60), rev(0.85, 0.3, 0.8)], 0),
        ("xiao", xiao, XIAO, 0, 0.2, [rev(0.85, 0.3, 0.8)], 0),
        ("guzheng", zheng, GUZHENG, -10, -0.2, [rev(0.85, 0.3, 0.8)], 0),
        ("bell", bell, BELL, -3, 0, [rev(0.9, 0.3, 0.8)], 0),
        ("taiko", taiko, TAIKO, 1, 0, [rev(0.75, 0.2, 0.9)], 0),
    ], {"length": 11.5, "tail": 2, "lufs": -18, "fade_out": 2.5})


if __name__ == "__main__":
    menu()
    battle_base()
    battle_war()
    boss()
    gameover()
