#!/usr/bin/env python3
"""Renders the score (compose.py) to seamless loops and encodes them for Godot.

For each loop: the MIDI is written three times back to back and rendered with FluidSynth
(MuseScore "MS Basic" GM soundfont, MIT). The middle repetition is cut out, so its start
already carries the reverb tail of the previous pass and its end flows into the next one:
the seam is sample-continuous by construction. Synthesised layers (the rin bowl) are added
with wrap-around. Loudness is normalised to an integrated target (BS.1770, gated) and the
result is encoded as 128 kbps MP3 (LAME) into assets/audio/music/.

Run: python3 tools/audio/render.py   (needs fluidsynth, lame, mido, numpy, scipy)
Env: SF2 overrides the soundfont path.
"""
import os
import subprocess
import tempfile

import numpy as np
from scipy.io import wavfile

import compose
from dsp import SR, k_weight, rin
from score import write_midi

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "assets", "audio", "music")
SF2 = os.environ.get("SF2", "/Applications/MuseScore 4.app/Contents/Resources/sound/MS Basic.sf3")
CEILING = 10 ** (-1.5 / 20)


def integrated_lufs(x):
    """BS.1770-4 integrated loudness of a (n, 2) float signal."""
    kw = np.stack([k_weight(x[:, c]) for c in range(x.shape[1])], axis=1)
    block, hop = int(0.4 * SR), int(0.1 * SR)
    p = np.square(kw).sum(axis=1)
    c = np.concatenate([[0.0], np.cumsum(p)])
    starts = np.arange(0, len(p) - block, hop)
    z = (c[starts + block] - c[starts]) / block
    lk = -0.691 + 10 * np.log10(z + 1e-12)
    z = z[lk > -70]
    rel = -0.691 + 10 * np.log10(np.mean(z)) - 10
    z = z[(-0.691 + 10 * np.log10(z + 1e-12)) > rel]
    return -0.691 + 10 * np.log10(np.mean(z))


def fluid(parts, bpm, beats, repeats, tail):
    with tempfile.TemporaryDirectory() as td:
        mid, wav = os.path.join(td, "s.mid"), os.path.join(td, "s.wav")
        write_midi(mid, parts, bpm, repeats, beats, tail)
        subprocess.run(["fluidsynth", "-ni", "-q", "-C0", "-R1", "-g", "0.6", "-r", str(SR),
                        "-O", "float", "-T", "wav", "-F", wav, SF2, mid], check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        sr, x = wavfile.read(wav)
    assert sr == SR
    return x.astype(np.float64)


def loop_samples(bpm, beats):
    n = beats * 60 * SR / bpm
    assert abs(n - round(n)) < 1e-6, "loop must be a whole number of samples"
    return int(round(n))


def render_loop(parts, bpm, beats):
    n = loop_samples(bpm, beats)
    x = fluid(parts, bpm, beats, 3, 8)
    return x[n:2 * n].copy()


def add_wrapped(dst, src, at_sample, gain=1.0, pan=0.5):
    n = len(dst)
    idx = (at_sample + np.arange(len(src))) % n
    np.add.at(dst[:, 0], idx, src * gain * (1 - pan) * 2 ** 0.5)
    np.add.at(dst[:, 1], idx, src * gain * pan * 2 ** 0.5)


def soft_limit(x):
    print(f"    limiter input peak {20 * np.log10(np.max(np.abs(x))):5.1f} dBFS")
    knee = CEILING * 0.7
    a = np.abs(x)
    m = a > knee
    x[m] = np.sign(x[m]) * (knee + (CEILING - knee) * np.tanh((a[m] - knee) / (CEILING - knee)))
    return x


def to_lufs(x, target):
    return x * 10 ** ((target - integrated_lufs(x)) / 20)


def save(name, x, loop):
    os.makedirs(OUT, exist_ok=True)
    wav = os.path.join(tempfile.gettempdir(), name + ".wav")
    wavfile.write(wav, SR, (np.clip(x, -1, 1) * 32767).astype(np.int16))
    mp3 = os.path.join(OUT, name + ".mp3")
    subprocess.run(["lame", "--quiet", "-b", "128", "-q", "2", wav, mp3], check=True)
    print(f"{name:12s} {len(x) / SR:7.3f}s  {integrated_lufs(x):6.1f} LUFS  peak "
          f"{20 * np.log10(np.max(np.abs(x))):5.1f} dBFS  loop={loop}")


def menu():
    x = render_loop(compose.menu(), compose.MENU_BPM, compose.MENU_BEATS)
    bowl = rin(6.0, 587.33, 2.2) * 0.12
    beat = SR * 60 // compose.MENU_BPM
    for b in (0, 32):
        add_wrapped(x, bowl, b * beat + int(0.02 * SR), pan=0.62)
    save("menu", soft_limit(to_lufs(x, -18.0)), True)


def battle():
    bpm, beats = compose.BATTLE_BPM, compose.BATTLE_BEATS
    base = render_loop(compose.battle_base(), bpm, beats)
    war = render_loop(compose.battle_war(), bpm, beats)
    g_base = 10 ** ((-19.5 - integrated_lufs(base)) / 20)
    base = base * g_base
    # choose the war gain so base + war sits at -17 LUFS (the full-intensity mix)
    lo, hi = 0.0, 8.0
    for _ in range(30):
        mid = (lo + hi) / 2
        if integrated_lufs(base + war * mid) < -17.0:
            lo = mid
        else:
            hi = mid
    war = war * lo
    peak = np.max(np.abs(base + war))
    if peak > CEILING:  # keep the sum under the ceiling without touching the stems' balance
        base, war = base * CEILING / peak, war * CEILING / peak
    save("battle_base", base, True)
    save("battle_war", war, True)
    print(f"{'(base+war)':12s} {integrated_lufs(base + war):6.1f} LUFS")


def boss():
    x = render_loop(compose.boss(), compose.BOSS_BPM, compose.BOSS_BEATS)
    save("boss", soft_limit(to_lufs(x, -17.0)), True)


def gameover():
    x = fluid(compose.gameover(), compose.GAMEOVER_BPM, compose.GAMEOVER_BEATS, 1, 0)
    n = int(11.5 * SR)
    x = x[:n] if len(x) >= n else np.pad(x, ((0, n - len(x)), (0, 0)))
    bowl = rin(8.0, 587.33, 2.6) * 0.12
    x[:len(bowl), 0] += bowl[:n] * 0.9
    x[:len(bowl), 1] += bowl[:n] * 1.1
    fade = int(2.5 * SR)
    x[-fade:] *= (np.linspace(1, 0, fade) ** 2)[:, None]
    save("gameover", soft_limit(to_lufs(x, -18.0)), False)


if __name__ == "__main__":
    menu()
    battle()
    boss()
    gameover()
