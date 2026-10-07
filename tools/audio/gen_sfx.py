#!/usr/bin/env python3
"""Every MagicEndless sound effect: preset hits (rendered once by audiokit) layered with numpy.

Two steps, both run with the audiokit venv (arch -arm64 /tmp/audiokit/venv/bin/python):
  gen_sfx.py hits    writes build/sfx_hits.mid + build/sfx_hits.json: every tonal hit the set needs,
                     one instrument per track, one hit per 4 s slot (render it with render_all.sh)
  gen_sfx.py build   slices the rendered stems (build/stems_sfx_hits/*.wav) and layers each hit
                     with synthesised ink/paper/wood layers (dsp.py), then writes
                     assets/audio/sfx/<name>.wav (16-bit mono, names = AudioManager SFX keys)

Tonal sources: guzheng = Vital "Plucked String", bell = Serum 2 "BL - Wudang Mountain",
gong = Vital "Cinema Bells", tick = Vital "Ceramic", bianqing = Serum 2 "MAL - Hybrid Balafon",
xiao = Serum 2 "WIND - Pan Flute", taiko / woodblock = MS Basic GM 116 / 115. No sample is shipped
on its own: every effect layers at least two sources and is enveloped, filtered and normalised.
Key: D yu pentatonic (D F G A C), like the score.
"""
import json
import os
import sys

import numpy as np
from scipy.io import wavfile

from dsp import (SR, bandpass, drum, env_ar, env_exp, finish, fm, highpass, lowpass, noise, place,
                 room, sine_sweep, swept_band, t_axis, wood, write)

HERE = os.path.dirname(os.path.abspath(__file__))
BUILD = os.path.join(HERE, "build")
STEMS = os.path.join(BUILD, "stems_sfx_hits")
OUT = os.path.join(HERE, "..", "..", "assets", "audio", "sfx")
SLOT = 4.0  # seconds between hits on one track (60 bpm: one beat = one second)

# instrument key -> (spec instrument, list of (hit id, midi pitch, length s, velocity))
HITS = {
    "guzheng": ({"type": "vital", "preset": None, "find": "Plucked String"}, [
        ("D6", 86, 0.4, 100), ("D4", 62, 0.9, 96), ("F4", 65, 0.9, 96), ("G4", 67, 0.9, 96),
        ("A4", 69, 0.9, 96), ("C5", 72, 0.9, 96), ("D5", 74, 0.9, 100), ("G5", 79, 0.6, 96),
        ("A5", 81, 0.6, 96), ("A3", 57, 0.6, 90), ("G#3", 56, 0.6, 90), ("D#3", 51, 0.4, 100)]),
    "bell": ({"type": "serum2", "preset": "Bell/BL - Wudang Mountain"}, [
        ("D4", 62, 1.5, 90), ("A4", 69, 1.5, 90), ("D5", 74, 1.2, 90), ("A5", 81, 1.0, 96)]),
    "gong": ({"type": "vital", "preset": None, "find": "Cinema Bells"}, [("D3", 74, 2.0, 110)]),
    "tick": ({"type": "vital", "preset": None, "find": "Ceramic"}, [
        ("lo", 55, 0.1, 90), ("mid", 62, 0.1, 96), ("hi", 69, 0.1, 100)]),
    "bianqing": ({"type": "serum2", "preset": "Mallet/MAL - Hybrid Balafon"}, [
        ("D3", 50, 0.3, 110), ("D4", 62, 0.25, 110), ("A4", 69, 0.25, 110), ("D5", 74, 0.2, 110),
        ("G5", 79, 0.2, 110)]),
    "xiao": ({"type": "serum2", "preset": "Woodwind/WIND - Pan Flute"}, [
        ("A5", 81, 0.14, 90), ("D5", 74, 0.5, 90), ("G4", 67, 0.4, 84)]),
    "taiko": ({"type": "fluidsynth", "program": 116, "gain": 0.6}, [
        ("A1", 33, 1.0, 127), ("D2", 38, 1.0, 120), ("G2", 43, 0.6, 110), ("D3", 50, 0.4, 104)]),
    "woodblock": ({"type": "fluidsynth", "program": 115, "gain": 0.6}, [
        ("hi", 79, 0.2, 110), ("lo", 67, 0.2, 110)]),
}
S2 = "/Library/Audio/Presets/Xfer Records/Serum 2 Presets/Presets/Factory"


def _find_vital(name):
    for root, _, files in os.walk(os.path.expanduser("~/Music/Vital")):
        if name + ".vital" in files:
            return os.path.join(root, name + ".vital")
    raise FileNotFoundError(name)


def write_hits():
    sys.path.insert(0, "/tmp/audiokit")
    import midi_io
    os.makedirs(BUILD, exist_ok=True)
    mid = os.path.join(BUILD, "sfx_hits.mid")
    tracks, spec_tracks = [], []
    for i, (key, (inst, hits)) in enumerate(HITS.items()):
        inst = dict(inst)
        if inst["type"] == "vital":
            inst["preset"] = _find_vital(inst.pop("find"))
        elif inst["type"] == "serum2":
            inst["preset"] = f"{S2}/{inst['preset']}.SerumPreset"
        tracks.append([(k * SLOT, ln, pitch, vel, 0) for k, (_, pitch, ln, vel) in enumerate(hits)])
        spec_tracks.append({"name": key, "midi": mid, "track": i, "instrument": inst})
    midi_io.write_midi(mid, tracks, bpm=60)
    spec = {"out": os.path.join(BUILD, "sfx_hits.wav"), "lufs": -18, "subtype": "FLOAT", "tail": 4,
            "stems_dir": STEMS, "tracks": spec_tracks}
    with open(os.path.join(BUILD, "sfx_hits.json"), "w") as f:
        json.dump(spec, f, indent=1)
    print("wrote", mid)


_stems = {}


def hit(key, hid, dur):
    """Rendered preset hit as mono float, onset-trimmed, peak 1.0, length dur seconds."""
    if key not in _stems:
        sr, x = wavfile.read(os.path.join(STEMS, key + ".wav"))
        assert sr == SR
        _stems[key] = x.mean(axis=1) if x.ndim == 2 else x
    ids = [h[0] for h in HITS[key][1]]
    i0 = int(ids.index(hid) * SLOT * SR)
    seg = _stems[key][i0:i0 + int((dur + 0.2) * SR)].astype(np.float64)
    pk = np.max(np.abs(seg))
    assert pk > 1e-4, f"silent hit {key}/{hid}"
    start = int(np.argmax(np.abs(seg) > pk * 10 ** (-45 / 20)))
    start = max(0, start - int(0.001 * SR))
    seg = seg[start:start + int(dur * SR)]
    seg = np.pad(seg, (0, int(dur * SR) - len(seg)))
    seg = seg - np.mean(seg)
    fo = int(min(0.03, dur / 4) * SR)
    seg[-fo:] *= np.linspace(1, 0, fo) ** 2
    return seg / pk


def rng_for(name):
    return np.random.default_rng(sum(map(ord, name)) * 7919)


def brush_flick(dur, f0, f1, rng, q=2.5):
    return swept_band(noise(dur, rng), f0, f1, q) * env_ar(dur, 0.012, dur * 0.35)


def buf(d):
    return np.zeros(int(d * SR))


# ---- player spells (one per bullet mode) -------------------------------------------------

def shoot_normal(r):
    # a brush flick rising with a tiny high guzheng tick
    d = 0.17
    x = brush_flick(d, 1800, 5200, r) * 0.8
    x += 0.45 * hit("guzheng", "D6", d) * env_exp(d, 0.05)
    return finish(room(x), lufs=-22)


def shoot_pierce(r):
    # bamboo dart: a hard ceramic click and a whistling streak
    d = 0.18
    x = 0.7 * hit("tick", "hi", d) + 0.3 * wood(d, 1900, r, 1.2)
    x += 0.4 * bandpass(noise(d, r), 4000, 9000) * env_exp(d, 0.03)
    x += 0.2 * sine_sweep(d, 1750, 1180, 20) * env_exp(d, 0.05)
    return finish(room(x), lufs=-22)


def shoot_burst(r):
    # three paper flicks fanned out, with three ceramic ticks
    d = 0.2
    x = buf(d)
    for k, (at, f, t) in enumerate([(0.0, 2600, "mid"), (0.035, 3300, "hi"), (0.07, 2200, "lo")]):
        place(x, brush_flick(0.09, f, f * 1.9, r, 3.0) * (1.0 - 0.15 * k), at)
        place(x, 0.35 * hit("tick", t, 0.08), at)
    return finish(room(x), lufs=-22)


def shoot_ricochet(r):
    # a bianqing "tok" with an upward FM rebound
    d = 0.2
    x = 0.8 * hit("bianqing", "D5", d) + 0.3 * fm(d, 1240, 1.5, 1.2, 0.05)
    return finish(room(x), lufs=-22)


def shoot_hex(r):
    # a low murmured curse: a muted low string under detuned FM, ink blooming
    d = 0.26
    x = 0.6 * hit("guzheng", "D#3", d) * env_exp(d, 0.12)
    x += 0.4 * fm(d, 155.6, 1.0007, 3.0, 0.12) + 0.3 * fm(d, 155.6 * 1.012, 2.0, 2.0, 0.09)
    x += 0.2 * lowpass(noise(d, r), 900) * env_exp(d, 0.06)
    return finish(room(lowpass(x, 3200)), lufs=-22)


def sword(r):
    # the vermilion crescent: a wide brush stroke sweeping down, a faint bell sing
    d = 0.32
    x = swept_band(noise(d, r), 5000, 900, 1.6) * env_ar(d, 0.03, 0.12)
    x += 0.18 * highpass(hit("bell", "A5", d), 1500) * env_exp(d, 0.1)
    return finish(room(x), lufs=-23)


# ---- auto-cast magic ----------------------------------------------------------------------

def arcane(r):
    # arcane bolt: a high guzheng pluck and a fast rising brush
    d = 0.4
    x = 0.8 * hit("guzheng", "A5", d) * env_exp(d, 0.2)
    place(x, 0.4 * brush_flick(0.18, 2000, 7000, r), 0.0)
    return finish(room(x), lufs=-21)


def nova(r):
    # frost nova: taiko thump, paper crackle, cold bell
    d = 0.9
    x = 0.8 * hit("taiko", "G2", d) + 0.4 * drum(d, 160, 70, 0.18, r, 0.5)
    crackle = highpass(noise(d, r), 3000) * (r.random(int(d * SR)) > 0.985) * 3.0
    x += 0.4 * crackle * env_exp(d, 0.2)
    x += 0.35 * hit("bell", "D5", d)
    return finish(room(x, 0.2), lufs=-18, fade_out=0.1)


def chain(r):
    # chain sigil: a carved ring struck three times up the scale D-G-A
    d = 0.45
    x = buf(d)
    for k, (b, g) in enumerate([("D5", "D5"), ("G5", "G5"), ("D5", "A5")]):
        place(x, 0.6 * hit("bianqing", b if k < 2 else "A4", 0.18) + 0.4 * hit("guzheng", g, 0.18), k * 0.07)
    return finish(room(x), lufs=-21)


def meteor(r):
    # meteor rain: falling streak then a heavy taiko landing
    d = 1.0
    x = buf(d)
    place(x, swept_band(noise(0.35, r), 6000, 500, 2.0) * env_ar(0.35, 0.2, 0.3) * 0.6, 0.0)
    place(x, hit("taiko", "A1", 0.7) + 0.5 * drum(0.7, 110, 48, 0.22, r, 0.8), 0.3)
    return finish(room(x, 0.18), lufs=-17, fade_out=0.1)


# ---- combat feedback ----------------------------------------------------------------------

def hit_(r):
    # a paper punch: dull, tiny, very frequent
    d = 0.09
    x = 0.7 * drum(d, 420, 230, 0.03, r, 0.9) + 0.3 * hit("tick", "lo", d)
    x += 0.25 * bandpass(noise(d, r), 800, 3000) * env_exp(d, 0.012)
    return finish(x, lufs=-24)


def enemy_die(r):
    # an ink splat: wet noise bloom and a low bianqing knock
    d = 0.38
    splat = lowpass(noise(d, r), 2400) * env_exp(d, 0.06) * (1 + 0.6 * np.sin(2 * np.pi * 31 * t_axis(d)))
    x = 0.7 * splat + 0.6 * hit("bianqing", "D3", d) + 0.4 * drum(d, 200, 90, 0.07, r, 0.2)
    return finish(room(x), lufs=-21)


def enemy_shoot(r):
    # a blowgun breath: xiao chiff over a breath band
    d = 0.16
    x = 0.5 * hit("xiao", "A5", d) + 0.6 * bandpass(noise(d, r), 1200, 4200) * env_ar(d, 0.02, 0.05)
    return finish(x, lufs=-25)


def hurt(r):
    # struck: a taiko body blow with a woodblock rim crack
    d = 0.42
    x = 0.9 * hit("taiko", "D2", d) + 0.5 * hit("woodblock", "lo", d) + 0.4 * drum(d, 130, 55, 0.14, r, 0.7)
    x += 0.25 * lowpass(noise(d, r), 1200) * env_exp(d, 0.03)
    return finish(room(x), lufs=-16)


def shield_on(r):
    # an indigo ring closes: a bell strike and a breath drawn in
    d = 0.7
    x = 0.6 * hit("bell", "A4", d) + 0.3 * swept_band(noise(d, r), 600, 2400, 2.0) * env_ar(d, 0.15, 0.2)
    return finish(room(x), lufs=-20, fade_out=0.12)


def shield_off(r):
    d = 0.4
    x = 0.4 * hit("bell", "D4", d) * env_exp(d, 0.15)
    x += 0.3 * swept_band(noise(d, r), 2400, 500, 2.0) * env_ar(d, 0.02, 0.1)
    return finish(room(x), lufs=-22, fade_out=0.08)


def shield_hit(r):
    # a blow turned aside: bianqing thock and a bright bell ping
    d = 0.42
    x = 0.7 * hit("bianqing", "A4", d) + 0.45 * hit("bell", "A5", d) * env_exp(d, 0.15)
    return finish(room(x), lufs=-19, fade_out=0.06)


def dash(r):
    # a fast dry-brush drag upward with a breath of xiao
    d = 0.22
    x = swept_band(noise(d, r), 700, 4200, 1.8) * env_ar(d, 0.01, 0.08)
    x += 0.2 * highpass(hit("xiao", "G4", d), 800) * env_ar(d, 0.01, 0.08)
    return finish(room(x), lufs=-20)


def mode_switch(r):
    # a clack of two small blocks
    d = 0.15
    x = buf(d)
    place(x, hit("woodblock", "hi", 0.1) + 0.3 * hit("tick", "mid", 0.1), 0.0)
    place(x, 0.7 * hit("woodblock", "lo", 0.1) + 0.3 * wood(0.1, 1980, r), 0.045)
    return finish(x, lufs=-22)


# ---- run structure ------------------------------------------------------------------------

def card_show(r):
    # three leaves of paper fanned onto the page, a soft pluck under the last
    d = 0.5
    x = buf(d)
    for k in range(3):
        place(x, swept_band(noise(0.14, r), 900, 2600, 1.5) * env_ar(0.14, 0.03, 0.06) * 0.7, k * 0.09)
    place(x, 0.25 * hit("guzheng", "A4", 0.3), 0.18)
    return finish(room(x), lufs=-22, fade_out=0.06)


def card_pick(r):
    # chosen: guzheng rising D-A-D and the seal pressed in (taiko)
    d = 0.8
    x = buf(d)
    for k, n in enumerate(["D4", "A4", "D5"]):
        place(x, 0.5 * hit("guzheng", n, d - k * 0.06), k * 0.06)
    place(x, 0.6 * hit("taiko", "D3", 0.3), 0.16)
    return finish(room(x, 0.15), lufs=-17, fade_out=0.12)


def wave_start(r):
    # the seal-stamp thud: a low taiko and a carved block on paper
    d = 0.8
    x = 1.0 * hit("taiko", "A1", d) + 0.5 * drum(d, 95, 45, 0.25, r, 1.0, 22)
    x += 0.4 * hit("woodblock", "lo", d) + 0.3 * lowpass(noise(d, r), 600) * env_exp(d, 0.04)
    return finish(room(x, 0.2, 0.08), lufs=-16, fade_out=0.12)


def wave_clear(r):
    # a guzheng run up the yu scale and the temple bell
    d = 1.5
    x = buf(d)
    for k, n in enumerate(["D4", "F4", "G4", "A4", "C5", "D5"]):
        place(x, 0.45 * hit("guzheng", n, 0.85), k * 0.07)
    place(x, 0.5 * hit("bell", "D5", 1.05), 0.42)
    return finish(room(x, 0.15), lufs=-17, fade_out=0.3)


def boss_appear(r):
    # the elite enters: two taiko blows, the low gong and a woodblock crack
    d = 1.6
    x = buf(d)
    place(x, hit("taiko", "A1", 0.7), 0.0)
    place(x, hit("taiko", "A1", 0.7), 0.32)
    place(x, 0.5 * hit("gong", "D3", 1.6) * env_exp(1.6, 0.7), 0.0)
    place(x, 0.7 * hit("woodblock", "hi", 0.2), 0.62)
    place(x, 0.7 * hit("woodblock", "hi", 0.2), 0.7)
    return finish(room(x, 0.2, 0.09), lufs=-16, fade_out=0.25)


def objective_success(r):
    d = 0.9
    x = buf(d)
    place(x, 0.5 * hit("guzheng", "A4", 0.7), 0.0)
    place(x, 0.5 * hit("guzheng", "D5", 0.7), 0.08)
    place(x, 0.35 * hit("bell", "A5", 0.75), 0.12)
    return finish(room(x), lufs=-18, fade_out=0.18)


def objective_fail(r):
    # a slack string falling a semitone and a dead taiko thud
    d = 0.65
    x = buf(d)
    place(x, 0.5 * lowpass(hit("guzheng", "A3", 0.5), 2000), 0.0)
    place(x, 0.5 * lowpass(hit("guzheng", "G#3", 0.5), 1800), 0.12)
    place(x, 0.4 * hit("taiko", "D3", 0.3) + 0.3 * drum(0.3, 140, 90, 0.06, r, 0.4), 0.12)
    return finish(room(x), lufs=-19, fade_out=0.12)


def player_die(r):
    # the brush drops: a long splat, one low drum and the gong
    d = 1.4
    x = 0.8 * hit("taiko", "A1", d) + 0.4 * hit("gong", "D3", d) * env_exp(d, 0.6)
    x += 0.5 * lowpass(noise(d, r), 1500) * env_exp(d, 0.12)
    return finish(room(x, 0.2, 0.09), lufs=-16, fade_out=0.3)


# ---- UI -----------------------------------------------------------------------------------

def ui_hover(r):
    # a fingertip on paper with the faintest ceramic tick
    d = 0.06
    x = 0.6 * bandpass(noise(d, r), 2500, 7000) * env_exp(d, 0.008) + 0.5 * hit("tick", "hi", d)
    return finish(x, lufs=-30, fade_out=0.012)


def ui_click(r):
    d = 0.09
    x = 0.7 * hit("bianqing", "D5", d) + 0.4 * wood(d, 1650, r, 0.8)
    return finish(x, lufs=-24)


def ui_confirm(r):
    # the double woodblock clap that opens a performance
    d = 0.34
    x = buf(d)
    place(x, hit("woodblock", "hi", 0.2) + 0.3 * wood(0.2, 1040, r, 1.2), 0.0)
    place(x, 0.9 * hit("woodblock", "hi", 0.2) + 0.3 * wood(0.2, 1040, r, 1.2), 0.11)
    return finish(room(x), lufs=-19, fade_out=0.06)


def ui_success(r):
    d = 0.6
    x = 0.6 * hit("guzheng", "D5", d) + 0.3 * hit("bell", "A5", d) * env_exp(d, 0.25)
    x += 0.3 * hit("taiko", "D3", d)
    return finish(room(x), lufs=-19, fade_out=0.1)


def ui_fail(r):
    d = 0.28
    x = 0.6 * hit("taiko", "G2", d) * env_exp(d, 0.08) + 0.4 * lowpass(hit("guzheng", "G#3", d), 1500)
    return finish(x, lufs=-22, fade_out=0.05)


SOUNDS = {f.__name__.rstrip("_"): f for f in [
    shoot_normal, shoot_pierce, shoot_burst, shoot_ricochet, shoot_hex, sword, arcane, nova, chain,
    meteor, hit_, enemy_die, enemy_shoot, hurt, shield_on, shield_off, shield_hit, dash, mode_switch,
    card_show, card_pick, wave_start, wave_clear, boss_appear, objective_success, objective_fail,
    player_die, ui_hover, ui_click, ui_confirm, ui_success, ui_fail]}


def build():
    os.makedirs(OUT, exist_ok=True)
    for name, fn in SOUNDS.items():
        x = fn(rng_for(name))
        write(os.path.join(OUT, name + ".wav"), x)
        print(f"{name:20s} {len(x) / SR:5.2f}s")


if __name__ == "__main__":
    {"hits": write_hits, "build": build}[sys.argv[1] if len(sys.argv) > 1 else "build"]()
