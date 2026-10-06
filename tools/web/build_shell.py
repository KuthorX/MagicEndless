#!/usr/bin/env python3
"""Builds html/loading_shell.html (the Web export's custom HTML shell) from shell.tpl.html.

Embeds a tiny Ma Shan Zheng subset (only the loader's glyphs) as base64 WOFF2, so the loading
page needs no external resources. Source font: FONT_SRC (default /tmp/me-art/fonts), see
tools/art/subset_fonts.py. Re-run after changing the loader text:  python3 tools/web/build_shell.py
"""
import base64
import io
import os

from fontTools import subset

HERE = os.path.dirname(__file__)
ROOT = os.path.join(HERE, "..", "..")
SRC = os.environ.get("FONT_SRC", "/tmp/me-art/fonts")
GLYPHS = "Magic Endless异世界无尽战斗Loading…加载中失败重新0123456789.%MB /·"


def brush_woff2_b64():
    opts = subset.Options()
    opts.flavor = "woff2"
    opts.layout_features = ["*"]
    font = subset.load_font(os.path.join(SRC, "MaShanZheng-Regular.ttf"), opts)
    sub = subset.Subsetter(opts)
    sub.populate(text=GLYPHS)
    sub.subset(font)
    buf = io.BytesIO()
    subset.save_font(font, buf, opts)
    return base64.b64encode(buf.getvalue()).decode("ascii")


def main():
    with open(os.path.join(HERE, "shell.tpl.html"), encoding="utf-8") as f:
        html = f.read().replace("__BRUSH_WOFF2__", brush_woff2_b64())
    out = os.path.join(ROOT, "html", "loading_shell.html")
    with open(out, "w", encoding="utf-8") as f:
        f.write(html)
    print(out, len(html), "bytes")


if __name__ == "__main__":
    main()
