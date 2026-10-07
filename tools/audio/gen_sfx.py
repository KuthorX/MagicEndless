#!/usr/bin/env python3
"""Synthesises every sound effect of MagicEndless ("War Grimoire" woodblock print).

The palette: brush on kozo paper, carved wood, a stamped seal, silk strings, taiko skin and
one bronze rin bowl. Nothing glows, so nothing is a laser: player shots are brush flicks,
enemies breathe darts, the wave counter is a seal pressed into paper.

Outputs 16-bit mono WAVs to assets/audio/sfx/<name>.wav (names = AudioManager SFX keys).
Run: python3 tools/audio/gen_sfx.py   (numpy + scipy). Deterministic (fixed seeds).
"""
import os

import numpy as np

from dsp import (SR, bandpass, drum, env_ar, env_exp, finish, fm, highpass, lowpass, modal,
                 noise, place, pluck, rin, room, sine_sweep, swept_band, t_axis, wood, write)

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "sfx")

# D "in" (miyako-bushi) scale, the key of the whole score: D Eb G A Bb.
D4 = 293.66


def semis(n):
    return D4 * 2 ** (n / 12)


def rng_for(name):
    return np.random.default_rng(sum(map(ord, name)) * 7919)


def brush_flick(dur, f0, f1, rng, q=2.5):
    x = swept_band(noise(dur, rng), f0, f1, q)
    return x * env_ar(dur, 0.012, dur * 0.35)


# ---- player spells (one per bullet mode) -------------------------------------------------

def shoot_normal(r):
    # a quick brush flick: paper hiss rising, a soft silk tick under it
    d = 0.16
    x = brush_flick(d, 1800, 5200, r) * 0.9
    x += 0.35 * pluck(d, semis(12), r, 0.985, 0.5) * env_exp(d, 0.05)
    return finish(room(x), lufs=-24)


def shoot_pierce(r):
    # bamboo dart: a hard thin click and a whistling streak
    d = 0.18
    x = 0.6 * wood(d, 1900, r, 1.2)
    x += 0.5 * bandpass(noise(d, r), 4000, 9000) * env_exp(d, 0.03)
    x += 0.25 * sine_sweep(d, semis(31), semis(24), 20) * env_exp(d, 0.05)
    return finish(room(x), lufs=-24)


def shoot_burst(r):
    # three paper flicks fanned out
    d = 0.2
    x = np.zeros(int(d * SR))
    for k, (at, f) in enumerate([(0.0, 2600), (0.035, 3300), (0.07, 2200)]):
        place(x, brush_flick(0.09, f, f * 1.9, r, 3.0) * (1.0 - 0.15 * k), at)
    return finish(room(x), lufs=-24)


def shoot_ricochet(r):
    # a woodblock "tok" with a rebounding upward bend
    d = 0.2
    x = 0.8 * wood(d, 1180, r)
    x += 0.4 * fm(d, 1240, 1.5, 1.2, 0.05)
    return finish(room(x), lufs=-24)


def shoot_hex(r):
    # a low murmured curse: detuned FM on a low Eb, ink blooming
    d = 0.26
    x = 0.6 * fm(d, semis(-11), 1.0007, 3.0, 0.12) + 0.5 * fm(d, semis(-11) * 1.012, 2.0, 2.0, 0.09)
    x += 0.25 * lowpass(noise(d, r), 900) * env_exp(d, 0.06)
    return finish(room(lowpass(x, 3000)), lufs=-24)


def sword(r):
    # the vermilion crescent: a wide brush stroke sweeping downward, a faint steel sing
    d = 0.3
    x = swept_band(noise(d, r), 5000, 900, 1.6) * env_ar(d, 0.03, 0.12)
    x += 0.12 * modal(d, [semis(29), semis(29) * 2.76], [0.12, 0.05], [1, 0.4])
    return finish(room(x), lufs=-25)


# ---- auto-cast magic ----------------------------------------------------------------------

def arcane(r):
    # arcane bolt: an indigo ink line drawn fast — plucked high koto + rising brush
    d = 0.35
    x = 0.7 * pluck(d, semis(19), r, 0.993, 0.8) * env_exp(d, 0.18)
    place(x, 0.4 * brush_flick(0.18, 2000, 7000, r), 0.0)
    return finish(room(x), lufs=-23)


def nova(r):
    # frost nova: an ink ring bursting outward — skin thump, paper crackle, cold rin
    d = 0.9
    x = 0.9 * drum(d, 160, 70, 0.18, r, 0.5)
    crackle = highpass(noise(d, r), 3000) * (r.random(int(d * SR)) > 0.985) * 3.0
    x += 0.5 * crackle * env_exp(d, 0.2)
    x += 0.35 * rin(d, semis(24), 0.5)
    return finish(room(x, 0.2), lufs=-20, fade_out=0.08)


def chain(r):
    # chain sigil: a carved ring stamped three times, stepping up the scale
    d = 0.42
    x = np.zeros(int(d * SR))
    for k, n in enumerate([0, 5, 7]):
        place(x, 0.7 * wood(0.15, semis(n + 12), r) + 0.3 * pluck(0.15, semis(n + 12), r, 0.99), k * 0.07)
    return finish(room(x), lufs=-23)


def meteor(r):
    # meteor rain: falling streak then a heavy taiko landing
    d = 0.9
    x = np.zeros(int(d * SR))
    place(x, swept_band(noise(0.35, r), 6000, 500, 2.0) * env_ar(0.35, 0.2, 0.3) * 0.6, 0.0)
    place(x, drum(0.55, 110, 48, 0.22, r, 0.8), 0.3)
    return finish(room(x, 0.18), lufs=-19, fade_out=0.06)


# ---- combat feedback ----------------------------------------------------------------------

def hit(r):
    # a paper punch: dull, tiny, very frequent
    d = 0.09
    x = 0.8 * drum(d, 420, 230, 0.03, r, 0.9) + 0.3 * bandpass(noise(d, r), 800, 3000) * env_exp(d, 0.012)
    return finish(x, lufs=-26)


def enemy_die(r):
    # an ink splat: wet noise bloom and a low wood knock
    d = 0.35
    splat = lowpass(noise(d, r), 2400) * env_exp(d, 0.06) * (1 + 0.6 * np.sin(2 * np.pi * 31 * t_axis(d)))
    x = 0.8 * splat + 0.6 * drum(d, 200, 90, 0.07, r, 0.2) + 0.3 * wood(d, 520, r, 0.6)
    return finish(room(x), lufs=-23)


def enemy_shoot(r):
    # a blowgun breath — enemies breathe darts at you
    d = 0.16
    x = bandpass(noise(d, r), 1200, 4200) * env_ar(d, 0.02, 0.05)
    x += 0.25 * sine_sweep(d, 900, 650, 12) * env_exp(d, 0.04)
    return finish(x, lufs=-27)


def hurt(r):
    # struck: a taiko rim crack on top of a low body blow
    d = 0.4
    x = 0.9 * drum(d, 130, 55, 0.14, r, 0.7) + 0.6 * wood(d, 820, r, 1.3)
    x += 0.3 * lowpass(noise(d, r), 1200) * env_exp(d, 0.03)
    return finish(room(x), lufs=-17)


def shield_on(r):
    # an indigo ring closes: soft rin strike, a breath drawn in
    d = 0.6
    x = 0.6 * rin(d, semis(7), 0.35) + 0.3 * swept_band(noise(d, r), 600, 2400, 2.0) * env_ar(d, 0.15, 0.2)
    return finish(room(x), lufs=-22, fade_out=0.08)


def shield_off(r):
    d = 0.35
    x = 0.4 * rin(d, semis(0), 0.12) + 0.3 * swept_band(noise(d, r), 2400, 500, 2.0) * env_ar(d, 0.02, 0.1)
    return finish(room(x), lufs=-24, fade_out=0.06)


def shield_hit(r):
    # a blow turned aside: wood thock and a bright rin ping
    d = 0.4
    x = 0.7 * wood(d, 640, r) + 0.45 * rin(d, semis(19), 0.15)
    return finish(room(x), lufs=-21, fade_out=0.05)


def dash(r):
    # a fast dry-brush drag upward
    d = 0.22
    x = swept_band(noise(d, r), 700, 4200, 1.8) * env_ar(d, 0.01, 0.08)
    return finish(room(x), lufs=-22)


def mode_switch(r):
    # a clack of two small blocks (the ledger flips a tab)
    d = 0.14
    x = np.zeros(int(d * SR))
    place(x, wood(0.1, 1500, r), 0.0)
    place(x, 0.7 * wood(0.1, 1980, r), 0.045)
    return finish(x, lufs=-24)


# ---- run structure ------------------------------------------------------------------------

def card_show(r):
    # three leaves of paper fanned onto the page
    d = 0.5
    x = np.zeros(int(d * SR))
    for k in range(3):
        place(x, swept_band(noise(0.14, r), 900, 2600, 1.5) * env_ar(0.14, 0.03, 0.06) * 0.7, k * 0.09)
    return finish(room(x), lufs=-24, fade_out=0.05)


def card_pick(r):
    # chosen: a koto rising D-A-D and the seal pressed into it
    d = 0.75
    x = np.zeros(int(d * SR))
    for k, n in enumerate([0, 7, 12]):
        place(x, 0.5 * pluck(d - k * 0.06, semis(n), r, 0.995, 0.7), k * 0.06)
    place(x, 0.7 * drum(0.2, 220, 120, 0.04, r, 0.6), 0.16)
    return finish(room(x, 0.15), lufs=-19, fade_out=0.1)


def wave_start(r):
    # the seal-stamp thud: a heavy carved block hitting paper on a drum
    d = 0.75
    x = 1.0 * drum(d, 95, 45, 0.25, r, 1.0, 22)
    x += 0.5 * wood(d, 300, r, 0.8) + 0.4 * lowpass(noise(d, r), 600) * env_exp(d, 0.04)
    return finish(room(x, 0.2, 0.08), lufs=-16, fade_out=0.1)


def wave_clear(r):
    # a koto run up the in-scale and a rin bowl
    d = 1.4
    x = np.zeros(int(d * SR))
    for k, n in enumerate([0, 1, 5, 7, 8, 12]):
        place(x, 0.45 * pluck(0.8, semis(n), r, 0.996, 0.6), k * 0.07)
    place(x, 0.5 * rin(0.95, semis(12), 0.6), 0.42)
    return finish(room(x, 0.15), lufs=-19, fade_out=0.25)


def boss_appear(r):
    # the elite enters: two odaiko blows and a hyoshigi crack
    d = 1.2
    x = np.zeros(int(d * SR))
    place(x, drum(0.7, 80, 38, 0.3, r, 0.9, 20), 0.0)
    place(x, drum(0.7, 80, 36, 0.35, r, 0.9, 20), 0.32)
    place(x, 0.8 * wood(0.3, 900, r, 1.4), 0.62)
    place(x, 0.8 * wood(0.3, 900, r, 1.4), 0.7)
    return finish(room(x, 0.2, 0.09), lufs=-16, fade_out=0.15)


def objective_success(r):
    d = 0.8
    x = np.zeros(int(d * SR))
    place(x, 0.5 * pluck(0.6, semis(7), r, 0.995), 0.0)
    place(x, 0.5 * pluck(0.6, semis(12), r, 0.995), 0.08)
    place(x, 0.35 * rin(0.6, semis(19), 0.35), 0.12)
    return finish(room(x), lufs=-20, fade_out=0.15)


def objective_fail(r):
    # a slack string and a dead wooden thud, falling a semitone (A to Ab-ish)
    d = 0.6
    x = np.zeros(int(d * SR))
    place(x, 0.5 * pluck(0.5, semis(-5), r, 0.99, 0.3), 0.0)
    place(x, 0.5 * pluck(0.5, semis(-6), r, 0.99, 0.3), 0.12)
    place(x, 0.5 * drum(0.3, 140, 90, 0.06, r, 0.4), 0.12)
    return finish(room(x), lufs=-21, fade_out=0.1)


def player_die(r):
    # the brush drops: a long splat and one low drum
    d = 1.0
    x = 0.8 * drum(d, 90, 34, 0.4, r, 0.8, 15)
    x += 0.5 * lowpass(noise(d, r), 1500) * env_exp(d, 0.12)
    return finish(room(x, 0.2, 0.09), lufs=-18, fade_out=0.2)


# ---- UI -----------------------------------------------------------------------------------

def ui_hover(r):
    # a fingertip on paper
    d = 0.05
    x = bandpass(noise(d, r), 2500, 7000) * env_exp(d, 0.008)
    return finish(x, lufs=-32, fade_out=0.01)


def ui_click(r):
    d = 0.08
    x = wood(d, 1650, r, 0.8)
    return finish(x, lufs=-26)


def ui_confirm(r):
    # the hyoshigi clap that opens a performance
    d = 0.32
    x = np.zeros(int(d * SR))
    place(x, wood(0.2, 1040, r, 1.2), 0.0)
    place(x, wood(0.2, 1040, r, 1.2) * 0.9, 0.11)
    return finish(room(x), lufs=-21, fade_out=0.05)


def ui_success(r):
    d = 0.5
    x = 0.6 * pluck(d, semis(12), r, 0.995, 0.6) + 0.3 * rin(d, semis(24), 0.25)
    x += 0.4 * drum(d, 230, 130, 0.04, r, 0.5)
    return finish(room(x), lufs=-21, fade_out=0.08)


def ui_fail(r):
    d = 0.25
    x = 0.7 * drum(d, 150, 110, 0.05, r, 0.3) + 0.3 * pluck(d, semis(-11), r, 0.98, 0.2)
    return finish(x, lufs=-24, fade_out=0.04)


SOUNDS = [shoot_normal, shoot_pierce, shoot_burst, shoot_ricochet, shoot_hex, sword,
          arcane, nova, chain, meteor, hit, enemy_die, enemy_shoot, hurt, shield_on, shield_off,
          shield_hit, dash, mode_switch, card_show, card_pick, wave_start, wave_clear,
          boss_appear, objective_success, objective_fail, player_die,
          ui_hover, ui_click, ui_confirm, ui_success, ui_fail]


def main():
    os.makedirs(OUT, exist_ok=True)
    for fn in SOUNDS:
        x = fn(rng_for(fn.__name__))
        write(os.path.join(OUT, fn.__name__ + ".wav"), x)
        print(f"{fn.__name__:20s} {len(x) / SR:5.2f}s")


if __name__ == "__main__":
    main()
