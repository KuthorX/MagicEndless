#!/usr/bin/env python3
"""Masters the rendered cues (tools/audio/build/<cue>.wav) into assets/audio/music/<cue>.mp3.

- menu / boss: already loop-folded and LUFS-normalised by the renderer; encoded as is.
- battle_base + battle_war: two sample-locked stems (AudioStreamSynchronized). The base sits at
  BASE_LUFS alone; the war stem gain is solved so base + war hits FULL_LUFS, then both are scaled
  together if the sum would pass the true-peak ceiling.
- gameover: trimmed/padded to 11.5 s with a fade (one-shot).
MP3: LAME 128 kbps CBR, 44.1 kHz stereo (the LAME gapless tag keeps decoded length exact).

Run: arch -arm64 /tmp/audiokit/venv/bin/python tools/audio/finish_music.py
"""
import os
import subprocess
import sys
import tempfile

import numpy as np
import soundfile as sf

sys.path.insert(0, "/tmp/audiokit")
import mixing as M  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
BUILD = os.path.join(HERE, "build")
OUT = os.path.join(HERE, "..", "..", "assets", "audio", "music")
SR = 44100
CEILING_DBTP = -1.0
BASE_LUFS, FULL_LUFS = -19.5, -17.5
LENGTHS = {"menu": 64.0, "battle_base": 75.0, "battle_war": 75.0, "boss": 144 * 60 / 140, "gameover": 11.5}


def load(cue):
    x, sr = sf.read(os.path.join(BUILD, cue + ".wav"), dtype="float64", always_2d=True)
    assert sr == SR
    x = x.T
    n = int(round(LENGTHS[cue] * SR))
    if cue != "gameover":
        assert x.shape[1] == n, f"{cue}: {x.shape[1]} samples, expected {n}"
    return x


def gain_to(x, target):
    return x * 10 ** ((target - M.lufs(x)) / 20)


def encode(cue, x):
    tp = M.true_peak_db(x)
    assert tp <= CEILING_DBTP + 0.05, f"{cue}: true peak {tp:.2f} dBTP"
    os.makedirs(OUT, exist_ok=True)
    with tempfile.TemporaryDirectory() as td:
        wav = os.path.join(td, cue + ".wav")
        sf.write(wav, x.T, SR, subtype="PCM_16")
        subprocess.run(["lame", "--quiet", "-b", "128", "-q", "2", wav, os.path.join(OUT, cue + ".mp3")],
                       check=True)
    print(f"{cue:12s} {x.shape[1] / SR:7.3f}s  {M.lufs(x):6.2f} LUFS  TP {tp:6.2f} dBTP")


def battle():
    base = gain_to(load("battle_base"), BASE_LUFS)
    war = load("battle_war")
    lo, hi = 0.0, 8.0
    for _ in range(30):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if M.lufs(base + war * mid) < FULL_LUFS else (lo, mid)
    war = war * lo
    over = M.true_peak_db(base + war) - (CEILING_DBTP - 0.3)
    if over > 0:
        g = 10 ** (-over / 20)
        base, war = base * g, war * g
    encode("battle_base", base)
    encode("battle_war", war)
    s = base + war
    print(f"{'(base+war)':12s} {M.lufs(s):6.2f} LUFS  TP {M.true_peak_db(s):6.2f} dBTP")


def gameover():
    x = load("gameover")
    n = int(LENGTHS["gameover"] * SR)
    x = x[:, :n] if x.shape[1] >= n else np.pad(x, ((0, 0), (0, n - x.shape[1])))
    f = int(2.5 * SR)
    x[:, -f:] *= np.linspace(1, 0, f) ** 2
    encode("gameover", x)


if __name__ == "__main__":
    for cue in ("menu", "boss"):
        encode(cue, load(cue))
    battle()
    gameover()
