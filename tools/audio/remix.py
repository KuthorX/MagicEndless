#!/usr/bin/env python3
"""Rebalances rendered cues from their stems, without re-rendering any instrument.

The renderer writes every processed stem (with its gain) to build/stems_<cue>/ and the spec it
used is copied to build/rendered/<cue>.json. When compose.py's track gains change, this script
applies the difference (new spec gain - rendered gain) to each stem, then repeats the renderer's
mix steps: sum, loop-fold or trim, LUFS-normalise, true-peak limit. The result is written to
build/<cue>.wav, the same as a fresh render.

Run: arch -arm64 /tmp/audiokit/venv/bin/python tools/audio/remix.py [cue ...]
"""
import json
import os
import sys

import numpy as np
import soundfile as sf

sys.path.insert(0, "/tmp/audiokit")
import mixing as M  # noqa: E402
import render as R  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
BUILD = os.path.join(HERE, "build")


def remix(cue):
    spec = json.load(open(os.path.join(BUILD, cue + ".json")))
    old = {t["name"]: t["gain_db"] for t in json.load(open(os.path.join(BUILD, "rendered", cue + ".json")))["tracks"]}
    stems = []
    for t in spec["tracks"]:
        x, _ = sf.read(os.path.join(BUILD, "stems_" + cue, t["name"] + ".wav"), dtype="float32", always_2d=True)
        stems.append(x.T * np.float32(10 ** ((t["gain_db"] - old[t["name"]]) / 20)))
    y = M.apply_fx(M.mix(stems), spec.get("master_fx"))
    y = M.fold_loop(y, float(spec["loop"])) if spec.get("loop") else R.trim_silence_end(y)
    y = M.normalize(y, float(spec.get("lufs", -18)), float(spec.get("ceiling_dbtp", -1.0)))
    if not spec.get("loop"):
        y = R.fade_out(y, float(spec.get("fade_out", 0.02)))
    sf.write(spec["out"], y.T, 44100, subtype=spec.get("subtype", "PCM_16"))
    M.spectrogram_png(y, os.path.splitext(spec["out"])[0] + ".png", cue)
    info = {"lufs": round(M.lufs(y), 2), "tp": round(M.true_peak_db(y), 2)}
    if spec.get("loop"):
        info["seam"] = M.seam_report(y)
    print(cue, json.dumps(info, default=float))


if __name__ == "__main__":
    for c in sys.argv[1:] or ["menu", "battle_base", "battle_war", "boss", "gameover"]:
        remix(c)
