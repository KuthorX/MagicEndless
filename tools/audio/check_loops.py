#!/usr/bin/env python3
"""Loop seam check without listening: decodes each Ogg Vorbis file with ffmpeg,
checks the decoded length against the musical loop length, and compares the step across the
seam (last sample -> first sample) with the ordinary sample-to-sample steps around it, plus the
RMS of the last and first 50 ms.

Usage: python3 tools/audio/check_loops.py assets/audio/music/{menu,battle_base,battle_war,boss}.ogg
"""
import subprocess
import sys

import numpy as np

SR = 44100
EXPECTED = {"menu": 64 * 60 / 60, "battle_base": 160 * 60 / 128, "battle_war": 160 * 60 / 128,
            "boss": 144 * 60 / 140}


def decode(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-ac", "2", "-ar", str(SR), "-"],
                         check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.float32).reshape(-1, 2).astype(np.float64)


for path in sys.argv[1:]:
    name = path.rsplit("/", 1)[-1].rsplit(".", 1)[0]
    x = decode(path)
    exp = int(round(EXPECTED.get(name, 0) * SR))
    w = int(0.05 * SR)
    steps = np.abs(np.diff(np.concatenate([x[-w:], x[:w]]), axis=0))
    seam = steps[w - 1].max()
    typical = np.percentile(steps.max(axis=1), 99)
    rms_end = 20 * np.log10(np.sqrt(np.mean(x[-w:] ** 2)) + 1e-9)
    rms_start = 20 * np.log10(np.sqrt(np.mean(x[:w] ** 2)) + 1e-9)
    ok = seam <= typical and len(x) == exp  # a downbeat may legitimately be louder than the bar before it
    print(f"{name:12s} samples {len(x)} (expected {exp}, diff {len(x) - exp:+d})  seam step {seam:.4f} "
          f"vs p99 step {typical:.4f}  rms end/start {rms_end:5.1f}/{rms_start:5.1f} dB  {'OK' if ok else 'CHECK'}")
