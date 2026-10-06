#!/usr/bin/env python3
"""Paints the title illustration and the player's mage with the shared brush (brush.py).

menu_print.png (1280x720, transparent; laid over the paper): a great dry enso; inside it the
vermilion-cloaked mage stands on a single horizon stroke under a vermilion sun, while a wave of
the game's own ink creatures (painted by gen_creatures.py) breaks through the circle toward him.
player.png (128x128): the same mage, drawn ~0.33 scale in the battle.

Everything is brushwork from one hand; there are no vector shapes. Deterministic.
Run: python3 tools/art/gen_menu_print.py   (after gen_creatures.py)
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw

import brush
import gen_creatures

ART = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "art")
W, H = 1280, 720
SS = 2  # supersampling for the illustration
SUMI = (30, 27, 24)
VERMILION = (216, 69, 43)
INDIGO = (39, 70, 107)
BONE = (244, 236, 216)


def layer(w, h):
    return np.zeros((h, w), dtype=np.float32)


def composite(size, layers):
    """Stack (alpha, rgb) layers into one RGBA image, later layers on top."""
    w, h = size
    rgb = np.zeros((h, w, 3), dtype=np.float32)
    alpha = np.zeros((h, w), dtype=np.float32)
    for a, col in layers:
        c = np.array(col, dtype=np.float32)
        rgb = rgb * (1.0 - a[..., None]) + c * a[..., None]
        alpha = alpha + a * (1.0 - alpha)
    out = np.dstack([np.clip(rgb / np.maximum(alpha[..., None], 1e-4) * (alpha[..., None] > 0), 0, 255), alpha * 255.0])
    return Image.fromarray(out.astype(np.uint8), "RGBA")


def cone(acc, rng, tip, base, width, dry=0.3):
    """A stroke that starts as a point and widens: hats, cloaks."""
    brush.stroke(acc, [tip, base], width, rng, dry=dry, pressure=lambda t: 0.08 + 0.92 * t ** 0.8)


def mage(cloak, ink, rng, x, y, s):
    """The mage standing at (x, y) = feet, s = pixels per unit (height is ~100 units)."""
    p = lambda ux, uy: (x + ux * s, y - uy * s)
    cone(cloak, rng, p(0, 74), p(0, 0), 60 * s, dry=0.25)
    cone(ink, rng, p(-3, 104), p(1, 64), 30 * s, dry=0.2)
    brush.stroke(ink, [p(-20, 66), p(22, 63)], 6 * s, rng, dry=0.3)
    brush.stroke(ink, [p(30, 98), p(26, 2)], 5 * s, rng, dry=0.35)
    brush.stroke(ink, brush.arc(*p(31, 102), 9 * s, math.radians(200), math.radians(500), steps=60), 3.5 * s, rng, dry=0.5)
    brush.stroke(cloak, [p(14, 44), p(28, 60)], 9 * s, rng, dry=0.4)


def sun(acc, rng, cx, cy, r):
    """A filled disc laid as a tight spiral, so the brush texture shows in the fill."""
    pts = []
    turns = 2.6
    for i in range(400):
        t = i / 399
        a = t * turns * math.tau
        rr = r * 0.82 * t
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    brush.stroke(acc, pts, r * 0.8, rng, dry=0.25, pressure=lambda t: 0.9 + 0.1 * t)


def creature_wave(acc_ink, eyes, rng, scale):
    """The horde: creatures painted by gen_creatures, advancing along the ground toward the mage."""
    path = brush.bezier((800, 770), (800, 580), (690, 600), (545, 528), steps=400)
    sprites = []
    for i, (name, paint) in enumerate(gen_creatures.CREATURES):
        c = np.zeros((gen_creatures.S * gen_creatures.SS,) * 2, dtype=np.float32)
        paint(c, np.random.default_rng(100 + i))
        sprites.append(Image.fromarray((c * 255).astype(np.uint8), "L"))
    count = 30
    for k in range(count):
        t = 0.04 + 0.92 * k / (count - 1) + rng.uniform(-0.015, 0.015)
        i = int(t * (len(path) - 1))
        (x0, y0), (x1, y1) = path[max(0, i - 1)], path[min(len(path) - 1, i + 1)]
        heading = math.degrees(math.atan2(y1 - y0, x1 - x0))
        lateral = rng.uniform(-60, 40) * (1.0 - t * 0.6)
        nx, ny = -(y1 - y0), (x1 - x0)
        nl = math.hypot(nx, ny) + 1e-6
        cx = path[i][0] + nx / nl * lateral
        cy = path[i][1] + ny / nl * lateral
        size = (0.55 + 0.9 * (1.0 - t) + rng.uniform(-0.12, 0.12)) * 128 * scale
        sprite = sprites[int(rng.integers(0, len(sprites)))].resize((int(size), int(size)), Image.Resampling.LANCZOS)
        sprite = sprite.rotate(-heading + rng.uniform(-12, 12), resample=Image.Resampling.BICUBIC, expand=True)
        a = np.asarray(sprite, dtype=np.float32) / 255.0
        ox, oy = int(cx * SS - a.shape[1] / 2), int(cy * SS - a.shape[0] / 2)
        _paste_max(acc_ink, a, ox, oy)
        _eyes(eyes, cx * SS, cy * SS, math.radians(heading), size / 128.0)


def _paste_max(dst, src, ox, oy):
    h, w = dst.shape
    sx0, sy0 = max(0, -ox), max(0, -oy)
    dx0, dy0 = max(0, ox), max(0, oy)
    dx1, dy1 = min(w, ox + src.shape[1]), min(h, oy + src.shape[0])
    if dx1 <= dx0 or dy1 <= dy0:
        return
    region = src[sy0:sy0 + dy1 - dy0, sx0:sx0 + dx1 - dx0]
    np.maximum(dst[dy0:dy1, dx0:dx1], region, out=dst[dy0:dy1, dx0:dx1])


def _eyes(eyes, cx, cy, ang, s):
    """Bone eyes with a vermilion pupil, as the game draws them on every creature."""
    d = ImageDraw.Draw(eyes)
    ca, sa = math.cos(ang), math.sin(ang)
    for side in (-1, 1):
        ex, ey = 7.0 * s, 7.0 * side * s
        px, py = cx + ex * ca - ey * sa, cy + ex * sa + ey * ca
        r = 4.4 * s
        d.ellipse([px - r, py - r * 0.8, px + r, py + r * 0.8], fill=BONE + (255,))
        qx, qy = px + 1.8 * s * ca, py + 1.8 * s * sa
        rp = 2.2 * s
        d.ellipse([qx - rp, qy - rp, qx + rp, qy + rp], fill=VERMILION + (255,))


def illustration():
    rng = np.random.default_rng(42)
    w, h = W * SS, H * SS
    enso_a, horizon, sun_a, cloak, ink, horde = (layer(w, h) for _ in range(6))
    brush.stroke(enso_a, brush.arc(430 * SS, 350 * SS, 290 * SS, math.radians(-62), math.radians(250), steps=900),
                 64 * SS, rng, dry=0.6)
    sun(sun_a, rng, 540 * SS, 236 * SS, 64 * SS)
    brush.stroke(horizon, brush.bezier((70 * SS, 552 * SS), (300 * SS, 540 * SS), (560 * SS, 556 * SS), (860 * SS, 544 * SS)),
                 22 * SS, rng, dry=0.7)
    mage(cloak, ink, rng, 300 * SS, 548 * SS, 1.7 * SS)
    eyes = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    creature_wave(horde, eyes, rng, 1.6)
    img = composite((w, h), [(sun_a, VERMILION), (enso_a, SUMI), (horizon, SUMI),
                             (horde, INDIGO), (cloak, VERMILION), (ink, SUMI)])
    img = Image.alpha_composite(img, eyes)
    return img.resize((W, H), Image.Resampling.LANCZOS)


def player_sprite():
    """The battle mage: the same figure inside an open bone ring (the player's sigil)."""
    rng = np.random.default_rng(7)
    size = 512
    ring, cloak, ink = (layer(size, size) for _ in range(3))
    brush.stroke(ring, brush.arc(256, 256, 226, math.radians(-80), math.radians(230), steps=300), 30, rng, dry=0.5)
    mage(cloak, ink, rng, 238, 470, 3.9)
    img = composite((size, size), [(ring, BONE), (cloak, VERMILION), (ink, SUMI)])
    return img.resize((128, 128), Image.Resampling.LANCZOS)


def main():
    illustration().save(os.path.join(ART, "menu_print.png"), optimize=True)
    player_sprite().save(os.path.join(ART, "player.png"), optimize=True)
    print("wrote menu_print.png and player.png to", os.path.abspath(ART))


if __name__ == "__main__":
    main()
