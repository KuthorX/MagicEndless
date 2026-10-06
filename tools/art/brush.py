"""One brush for every piece of art in the game.

A bristle model of a sumi brush dragged along a path: the brush is pressed at the head, bristles
spread with pressure, each bristle carries its own ink load and runs dry toward the tail (flying
white, "hihaku"). Every generator in tools/art paints with `stroke()`, so the menu illustration,
the creatures, the mage, the walls, the HUD bars and the enso all share one hand.

Canvases are float32 alpha arrays (h, w) in 0..1; ink is composited with max().
"""
import math

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


def resample(path, spacing=1.0):
    """Even spacing along a polyline (list of (x, y)); returns an (n, 2) array."""
    pts = np.asarray(path, dtype=np.float64)
    seg = np.sqrt(((pts[1:] - pts[:-1]) ** 2).sum(axis=1))
    dist = np.concatenate([[0.0], np.cumsum(seg)])
    total = dist[-1]
    n = max(2, int(total / spacing) + 1)
    s = np.linspace(0.0, total, n)
    return np.stack([np.interp(s, dist, pts[:, 0]), np.interp(s, dist, pts[:, 1])], axis=1)


def press(t, head=0.08, tail=0.12):
    """Default pressure: the brush lands, presses, then lifts toward a thinner tail."""
    landing = min(1.0, t / head) if head > 0 else 1.0
    lift = 1.0 - (1.0 - tail) * max(0.0, (t - 0.55) / 0.45) ** 1.6
    return (0.45 + 0.55 * math.sin(landing * math.pi * 0.5)) * lift


def stroke(canvas, path, width, rng, dry=0.5, ink=1.0, pressure=press, bristles=None, wander=0.10):
    """Drag the brush along `path` onto `canvas` (in place). `width` is the fully pressed width in
    canvas pixels; `dry` (0..1) is how quickly the outer bristles run out of ink."""
    h, w = canvas.shape
    pts = resample(path, 1.0)
    n = len(pts)
    tang = np.gradient(pts, axis=0)
    tang /= np.linalg.norm(tang, axis=1, keepdims=True) + 1e-9
    normal = np.stack([-tang[:, 1], tang[:, 0]], axis=1)
    count = bristles or int(np.clip(width * 0.9, 10, 90))
    line_w = max(1, int(round(width / count * 2.2)))
    t = np.linspace(0.0, 1.0, n)
    pr = np.array([pressure(x) for x in t])
    # Both edges of the stroke wander independently, so the outline is never ruled.
    # Smoothed over about half a brush width, so short fat strokes don't get jagged edges.
    k = max(5, int(width * 0.5))

    def walk():
        raw = np.cumsum(rng.standard_normal(n + 2 * k)) / math.sqrt(n + 2 * k) * wander * 6.0
        return np.convolve(raw, np.ones(k) / k, mode="same")[k:k + n]

    edge_a, edge_b = walk(), walk()
    img = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(img)
    total = float(np.sqrt(((pts[1:] - pts[:-1]) ** 2).sum(axis=1)).sum())
    head = min(0.45, width * 0.5 / max(total, 1.0))
    for b in range(count):
        f = b / max(1, count - 1) - 0.5
        load = rng.uniform(0.8, 1.2)
        outer = (abs(f) * 2.0) ** 0.7
        drain = dry * rng.uniform(0.5, 1.5) * (0.3 + outer)
        noise = np.cumsum(rng.standard_normal(n)) / math.sqrt(n)
        level = load - drain * 2.0 * t ** 1.3 + noise * dry * 0.6
        edge = edge_a if f < 0 else edge_b
        spread = f * (1.0 + edge * abs(f) * 2.0)
        pos = pts + normal * (spread * width * pr)[:, None]
        # Outer bristles touch down later than the centre: a rounded, pressed head.
        start = head * (1.0 - math.sqrt(max(0.0, 1.0 - (2.0 * f) ** 2)))
        alive = (t >= start) & (level > 0.15)
        # Streaky dropout that grows toward the tail as the bristle runs dry.
        streak = np.convolve(rng.standard_normal(n), np.ones(9) / 3.0, mode="same")
        alive &= streak < 2.4 - dry * 3.0 * t * t
        shade = int(255 * min(1.0, ink * (0.85 + 0.15 * load)))
        run = []
        for i in range(n):
            if alive[i]:
                run.append((pos[i, 0], pos[i, 1]))
            elif run:
                if len(run) > 1:
                    d.line(run, fill=shade, width=line_w)
                run = []
        if len(run) > 1:
            d.line(run, fill=shade, width=line_w)
    img = img.filter(ImageFilter.GaussianBlur(0.6))
    np.maximum(canvas, np.asarray(img, dtype=np.float32) / 255.0, out=canvas)
    return canvas


def arc(cx, cy, r, a0, a1, steps=180, rx=None, ry=None):
    """Points on an (elliptical) arc from angle a0 to a1 (radians)."""
    rx = r if rx is None else rx
    ry = r if ry is None else ry
    return [(cx + math.cos(a0 + (a1 - a0) * i / steps) * rx, cy + math.sin(a0 + (a1 - a0) * i / steps) * ry)
            for i in range(steps + 1)]


def bezier(p0, p1, p2, p3, steps=120):
    """Cubic Bezier points: lets generators describe a curved stroke with four control points."""
    out = []
    for i in range(steps + 1):
        t = i / steps
        u = 1.0 - t
        out.append((u ** 3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t ** 3 * p3[0],
                    u ** 3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t ** 3 * p3[1]))
    return out


def to_ink(alpha):
    """White ink with the given alpha, ready to be tinted in-engine."""
    a = (np.clip(alpha, 0.0, 1.0) * 255).astype(np.uint8)
    rgba = np.zeros(a.shape + (4,), dtype=np.uint8)
    rgba[..., :3] = 255
    rgba[..., 3] = a
    return Image.fromarray(rgba, "RGBA")
