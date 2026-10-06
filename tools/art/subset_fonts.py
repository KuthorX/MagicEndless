#!/usr/bin/env python3
"""Subsets the CJK display/body fonts to the characters the game actually uses.

Source fonts (OFL, not committed at full size) are read from FONT_SRC (default /tmp/me-art/fonts):
  NotoSerifSC-Regular.otf, NotoSerifSC-Bold.otf  (github.com/notofonts/noto-cjk, Serif/SubsetOTF/SC)
  MaShanZheng-Regular.ttf                        (github.com/google/fonts, ofl/mashanzheng)
Character set = every character in i18n/translations.csv, scripts/*.gd, scenes/*.tscn + printable ASCII + common CJK punctuation.
Re-run after adding new translated text:  FONT_SRC=/path python3 tools/art/subset_fonts.py
There is no fallback font (the game ships exactly two faces), so a missing character renders as tofu.
"""
import glob
import os
import string

from fontTools import subset

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
SRC = os.environ.get("FONT_SRC", "/tmp/me-art/fonts")
DST = os.path.join(ROOT, "assets", "fonts")
EXTRA = string.printable + "，。、：；！？（）【】「」『』《》—…·×％＋－／ "

JOBS = [
    ("NotoSerifSC-Regular.otf", "NotoSerifSC-Subset-Regular.otf"),
    ("NotoSerifSC-Bold.otf", "NotoSerifSC-Subset-Bold.otf"),
    ("MaShanZheng-Regular.ttf", "MaShanZheng-Subset.ttf"),
]


def used_text():
    paths = [os.path.join(ROOT, "i18n", "translations.csv")]
    paths += glob.glob(os.path.join(ROOT, "scripts", "*.gd")) + glob.glob(os.path.join(ROOT, "scenes", "*.tscn"))
    text = ""
    for p in paths:
        with open(p, encoding="utf-8") as f:
            text += f.read()
    return text + EXTRA


def main():
    chars = sorted(set(used_text()) - {"\n", "\r", "\t"})
    text = "".join(chars)
    for src_name, dst_name in JOBS:
        opts = subset.Options()
        opts.layout_features = ["*"]
        opts.name_IDs = ["*"]
        opts.notdef_outline = True
        font = subset.load_font(os.path.join(SRC, src_name), opts)
        sub = subset.Subsetter(opts)
        sub.populate(text=text)
        sub.subset(font)
        out = os.path.join(DST, dst_name)
        subset.save_font(font, out, opts)
        print(dst_name, os.path.getsize(out), "bytes,", len(chars), "chars")


if __name__ == "__main__":
    main()
