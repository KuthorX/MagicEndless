#!/usr/bin/env python3
"""Paints the material textures used by the game. Every brushed texture comes from the one
brush in brush.py, the same hand that paints the menu, the mage and the creatures.

Outputs (in assets/art/):
  paper.png  - tileable kozo paper (512x512): fibre, mottling, faint chain lines
  enso.png   - dry-brush enso ring (1024x1024, ink alpha): tinted in-engine
  stroke.png - one horizontal dry-brush stroke with flying-white streaks (512x96, ink alpha): HUD bars
  brush/stroke_<n>.png - six different wall strokes (512x96), so no two walls share a tip
  brush/daub_<n>.png   - three square daubs (256x256) for short/square obstacles
  grain.png  - tileable paper-grain threshold map (256x256, uniform values): ink coverage dithering
  focus.png  - a short vertical brush tick (24x64, ink alpha): the focus mark beside the chosen entry
  seal.png   - a seal impression (256x256, ink alpha): chipped edge, a few unprinted specks;
               9-slice for the wave and run-score seals
  slip.png   - a torn scrap of the same paper (256x128, RGBA): 9-slice backing for HUD text
  blot.png   - a round ink blot with a ragged bleed edge (256x256, ink alpha): attack timing

Run: python3 tools/art/gen_textures.py   (needs Pillow + numpy). Deterministic (fixed seeds).
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

import brush

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "art")
PAPER_RGB = np.array([237, 227, 204], dtype=np.float32)


def periodic_noise(size, rng, falloff):
    """Seamless noise: filtered white noise in the frequency domain (periodic by construction)."""
    white = rng.standard_normal((size, size))
    f = np.fft.fftfreq(size)
    fx, fy = np.meshgrid(f, f)
    radius = np.sqrt(fx * fx + fy * fy)
    radius[0, 0] = 1.0
    spectrum = np.fft.fft2(white) / (radius ** falloff)
    spectrum[0, 0] = 0.0
    out = np.real(np.fft.ifft2(spectrum))
    return (out - out.mean()) / (out.std() + 1e-6)


def paper(size=512):
    rng = np.random.default_rng(7)
    mottle = periodic_noise(size, rng, 1.9) * 3.0
    grain = periodic_noise(size, rng, 0.2) * 2.2
    base = np.clip(PAPER_RGB[None, None, :] + (mottle + grain)[..., None] * np.array([1.0, 1.0, 1.15]), 0, 255)
    img = Image.fromarray(base.astype(np.uint8), "RGB")
    # Kozo fibres: thin curved strands, drawn on a 3x3 tiling so they wrap seamlessly.
    layer = Image.new("RGBA", (size * 3, size * 3), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for _ in range(900):
        x, y = rng.uniform(0, size), rng.uniform(0, size)
        ang = rng.uniform(0, math.tau)
        length = rng.uniform(4, 16)
        dark = rng.random() < 0.45
        col = (130, 110, 80, int(rng.uniform(10, 26))) if dark else (255, 252, 240, int(rng.uniform(50, 110)))
        pts = []
        for i in range(9):
            t = i / 8.0
            ang += rng.uniform(-0.25, 0.25)
            pts.append((x + math.cos(ang) * length * t, y + math.sin(ang) * length * t))
        for ox in (0, size, 2 * size):
            for oy in (0, size, 2 * size):
                d.line([(px + ox, py + oy) for px, py in pts], fill=col, width=1)
    fibres = layer.crop((size, size, 2 * size, 2 * size))
    img = Image.alpha_composite(img.convert("RGBA"), fibres)
    # Faint laid/chain lines of hand-made paper (vertical, every 64px).
    arr = np.asarray(img).astype(np.float32)
    xs = np.arange(size)
    chain = (np.abs(((xs + 8) % 64) - 32) > 31).astype(np.float32) * 4.0
    arr[..., :3] -= chain[None, :, None]
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA").convert("RGB")


def enso(size=1024):
    """One dry-brush circle, opened where the brush lifts."""
    rng = np.random.default_rng(23)
    acc = np.zeros((size, size), dtype=np.float32)
    path = brush.arc(size / 2.0, size / 2.0, size * 0.40, math.radians(-70), math.radians(248), steps=720)
    brush.stroke(acc, path, size * 0.085, rng, dry=0.55)
    return brush.to_ink(acc)


def to_ink(alpha, blur=0.0):
    img = Image.fromarray((alpha * 255).astype(np.uint8), "L")
    if blur > 0:
        img = img.filter(ImageFilter.GaussianBlur(blur))
    rgba = Image.new("RGBA", img.size, (255, 255, 255, 0))
    rgba.putalpha(img)
    return rgba


def stroke(seed=31, w=512, h=96):
    """One horizontal stroke with a pressed head and a dry tail: HUD bars and walls."""
    rng = np.random.default_rng(seed)
    acc = np.zeros((h, w), dtype=np.float32)
    bow = rng.uniform(-4, 4)
    path = brush.bezier((30, h / 2 + rng.uniform(-3, 3)), (w * 0.35, h / 2 + bow), (w * 0.7, h / 2 - bow), (w - 10, h / 2 + rng.uniform(-4, 4)))
    # Walls need body to the end, so the brush lifts only a little before the tail.
    brush.stroke(acc, path, h * 0.6, rng, dry=rng.uniform(0.35, 0.6), pressure=lambda t: brush.press(t, tail=0.55))
    return brush.to_ink(acc)


def grain(size=256):
    """Fibrous grain with a uniform value histogram: ink coverage = step(grain, alpha)."""
    rng = np.random.default_rng(53)
    fine = periodic_noise(size, rng, 0.55)
    fibre = periodic_noise(size, rng, 1.2)
    g = fine + 0.6 * fibre
    ranks = g.flatten().argsort().argsort().reshape(g.shape).astype(np.float32)
    return Image.fromarray((ranks / ranks.max() * 255).astype(np.uint8), "L")


def focus_tick():
    """A short vertical tick, pressed at the top and lifted at the bottom."""
    rng = np.random.default_rng(61)
    acc = np.zeros((64, 24), dtype=np.float32)
    brush.stroke(acc, [(12, 6), (11, 58)], 16, rng, dry=0.4)
    return brush.to_ink(acc)


def daub(seed=37, size=256):
    """A short, very wide stroke: a square block cut in one movement of a broad brush."""
    rng = np.random.default_rng(seed)
    acc = np.zeros((size, size), dtype=np.float32)
    y = size / 2 + rng.uniform(-6, 6)
    brush.stroke(acc, [(20, y), (size * 0.5, y + rng.uniform(-6, 6)), (size - 20, y)], size * 0.6, rng, dry=0.4, pressure=lambda t: brush.press(t, head=0.3, tail=0.7))
    return brush.to_ink(acc)


def seal(size=256):
    """Seal-paste impression: a solid block with a chipped edge and a few unprinted specks."""
    rng = np.random.default_rng(71)
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    edge = np.minimum(np.minimum(xx, yy), np.minimum(size - 1 - xx, size - 1 - yy))
    rough = periodic_noise(size, rng, 1.7) * 2.6 + periodic_noise(size, rng, 0.9) * 0.35
    body = np.clip((edge + rough - 6.0) * 0.8, 0, 1)
    speck = periodic_noise(size, rng, 1.2) > 3.4
    alpha = body
    alpha[speck] *= 0.15
    return to_ink(np.clip(alpha, 0, 1), blur=0.4)


def slip(w=256, h=128):
    """A scrap torn from the page: paper fibre colour with a soft deckle edge on all sides."""
    rng = np.random.default_rng(83)
    base = np.asarray(paper().convert("RGB")).astype(np.float32)[:h, :w] * 1.02
    n = periodic_noise(256, rng, 1.5)[:h, :w] * 1.6 + periodic_noise(256, rng, 0.7)[:h, :w] * 0.5
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    edge = np.minimum(np.minimum(xx, yy), np.minimum(w - 1 - xx, h - 1 - yy))
    alpha = np.clip((edge + n - 4.0) * 0.7, 0, 1)
    rgba = np.dstack([np.clip(base, 0, 255), alpha * 255]).astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def blot(size=256):
    """An ink blot with a ragged bleed edge, solid inside (the print has no translucency)."""
    rng = np.random.default_rng(41)
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    c = (size - 1) / 2.0
    ang = np.arctan2(yy - c, xx - c)
    r = np.sqrt((xx - c) ** 2 + (yy - c) ** 2) / (size * 0.46)
    wobble = np.zeros_like(r)
    for k, amp in ((3, 0.035), (7, 0.025), (13, 0.018), (29, 0.010)):
        wobble += amp * np.sin(ang * k + rng.uniform(0, math.tau))
    rr = r + wobble + periodic_noise(size, rng, 1.0) * 0.012
    alpha = np.clip((1.0 - rr) * 30.0, 0, 1)
    return to_ink(alpha, blur=0.6)


def main():
    os.makedirs(OUT, exist_ok=True)
    paper().save(os.path.join(OUT, "paper.png"), optimize=True)
    enso().save(os.path.join(OUT, "enso.png"), optimize=True)
    stroke().save(os.path.join(OUT, "stroke.png"), optimize=True)
    os.makedirs(os.path.join(OUT, "brush"), exist_ok=True)
    for i in range(6):
        stroke(300 + i * 7).save(os.path.join(OUT, "brush", "stroke_%d.png" % i), optimize=True)
    for i in range(3):
        daub(400 + i * 5).save(os.path.join(OUT, "brush", "daub_%d.png" % i), optimize=True)
    grain().save(os.path.join(OUT, "grain.png"), optimize=True)
    focus_tick().save(os.path.join(OUT, "focus.png"), optimize=True)
    blot().save(os.path.join(OUT, "blot.png"), optimize=True)
    slip().save(os.path.join(OUT, "slip.png"), optimize=True)
    seal().save(os.path.join(OUT, "seal.png"), optimize=True)
    print("wrote paper, enso, strokes, daubs, blot, slip, seal, grain, focus to", os.path.abspath(OUT))


if __name__ == "__main__":
    main()
