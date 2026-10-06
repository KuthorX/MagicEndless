#!/usr/bin/env python3
"""Paints the ink creatures (one per enemy type) with the shared brush (brush.py).

Each creature is two to four strokes: a fat body stroke laid front-to-back (pressed, round head
at the front; the dry tail trails behind), plus thin strokes for claws, horns, lances or tubes.
Creatures face +x (the game rotates them toward their heading). The ink is white alpha, tinted
in-engine (indigo; sumi for elites). Eyes are drawn by the game so pupils can carry the pigment.
Output: assets/art/creatures/<name>.png (128x128). Run: python3 tools/art/gen_creatures.py
"""
import math
import os

import numpy as np
from PIL import Image

import brush

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "art", "creatures")
S = 128
SS = 4  # supersampling
C = S * SS / 2


def P(x, y):
    """Creature space (-64..64, +x = forward) to supersampled canvas pixels."""
    return (C + x * SS, C + y * SS)


def line(acc, rng, pts, width, dry=0.4, tail=0.15):
    brush.stroke(acc, [P(x, y) for x, y in pts], width * SS, rng, dry=dry, pressure=lambda t: brush.press(t, tail=tail))


def curve(acc, rng, p0, p1, p2, p3, width, dry=0.45, tail=0.1):
    line(acc, rng, brush.bezier(p0, p1, p2, p3, steps=40), width, dry, tail)


def body(acc, rng, front, back, width, dry=0.55):
    """The body: one fat stroke laid from the head backwards, lifting into a dry tail."""
    line(acc, rng, [front, ((front[0] + back[0]) / 2, (front[1] + back[1]) / 2 + rng.uniform(-2, 2)), back], width, dry, tail=0.2)


def ring(acc, rng, r, width, dry=0.5):
    path = brush.arc(C, C, r * SS, math.radians(-40), math.radians(285), steps=120)
    brush.stroke(acc, path, width * SS, rng, dry=dry, pressure=lambda t: brush.press(t, tail=0.4))


def chaser(acc, rng):
    body(acc, rng, (16, 0), (-30, 0), 34)
    for y in (-12, 0, 12):
        line(acc, rng, [(14, y * 0.7), (36, y * 1.3)], 7)


def shooter(acc, rng):
    body(acc, rng, (14, 0), (-26, 2), 38, dry=0.4)
    line(acc, rng, [(10, 0), (36, 0)], 10, dry=0.2, tail=0.7)


def dasher(acc, rng):
    body(acc, rng, (28, 0), (-36, 0), 22, dry=0.7)
    curve(acc, rng, (8, -6), (-4, -16), (-16, -22), (-30, -22), 8)
    curve(acc, rng, (8, 6), (-4, 16), (-16, 22), (-30, 22), 8)


def sniper(acc, rng):
    body(acc, rng, (10, 0), (-26, 0), 30)
    line(acc, rng, [(8, 0), (50, 0)], 5, dry=0.2, tail=0.4)
    line(acc, rng, [(-12, -8), (-28, -24)], 6)
    line(acc, rng, [(-12, 8), (-28, 24)], 6)


def artillery(acc, rng):
    body(acc, rng, (16, 0), (-22, 0), 46, dry=0.35)
    for y in (-16, 0, 16):
        line(acc, rng, [(-10, y), (-36, y * 1.15)], 9, dry=0.2, tail=0.8)


def warden(acc, rng):
    ring(acc, rng, 20, 20, dry=0.4)


def warlock(acc, rng):
    body(acc, rng, (14, 0), (-14, 0), 36, dry=0.3)
    for y, bend in ((-14, -10), (-5, -4), (5, 4), (14, 10)):
        curve(acc, rng, (-6, y), (-18, y + bend), (-28, y - bend), (-42, y * 1.5), 7)


def beacon(acc, rng):
    ring(acc, rng, 20, 12, dry=0.6)
    line(acc, rng, [(4, 0), (-4, 0)], 14, dry=0.0, tail=1.0)
    line(acc, rng, [(22, 0), (42, 0)], 5, dry=0.3)


def lancer(acc, rng):
    body(acc, rng, (6, 0), (-26, 0), 26)
    line(acc, rng, [(4, 0), (56, 0)], 6, dry=0.15, tail=0.3)
    line(acc, rng, [(-8, -8), (-2, -26)], 7)
    line(acc, rng, [(-8, 8), (-2, 26)], 7)


CREATURES = [
    ("chaser", chaser),
    ("shooter", shooter),
    ("dasher", dasher),
    ("sniper", sniper),
    ("artillery", artillery),
    ("warden", warden),
    ("warlock", warlock),
    ("beacon", beacon),
    ("lancer", lancer),
]


def main():
    os.makedirs(OUT, exist_ok=True)
    for i, (name, paint) in enumerate(CREATURES):
        rng = np.random.default_rng(100 + i)
        acc = np.zeros((S * SS, S * SS), dtype=np.float32)
        paint(acc, rng)
        img = brush.to_ink(acc).resize((S, S), Image.Resampling.LANCZOS)
        img.save(os.path.join(OUT, name + ".png"), optimize=True)
    print("wrote", len(CREATURES), "creatures to", os.path.abspath(OUT))


if __name__ == "__main__":
    main()
