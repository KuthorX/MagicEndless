"""The MagicEndless score, written as code. Key: D, in (miyako-bushi) scale; the boss in iwato.

Tracks
  menu         60 bpm, 16 bars (64.0 s): ensō / red sun. Bowed drone, sparse koto, two shakuhachi
               phrases, one odaiko pulse per half (the red sun rising), a rin bowl.
  battle_base 128 bpm, 40 bars (75.0 s): shamisen ostinato, koto, shakuhachi theme, light
               hyoshigi + shime. Always playing in a fight.
  battle_war  same grid: taiko ensemble, chappa, shinobue doubling. Faded in wave by wave.
  boss        140 bpm, 36 bars (61.7 s), D iwato: shamisen tremolo, hichiriki-like reed, heavy taiko.
  gameover     60 bpm, one-shot sting (~11 s): the brush lifted from the page.
"""
import numpy as np

from score import (CHINA, CLAVES, FLOOR_HI, FLOOR_LO, IN_SCALE, IWATO, KICK, KOTO, MELODIC_TOM,
                   PICCOLO, SHAKUHACHI, SHAMISEN, SHANAI, STRINGS_SLOW, TAIKO, TIMPANI,
                   TOM_LO, TOM_MID, WOOD_HI, WOOD_LO, Part, deg)

D2, D3, D4, D5 = 38, 50, 62, 74


def snap(pitch, scale=IN_SCALE, root=D3):
    """Nearest pitch in the scale (ties go down)."""
    best = None
    for o in range(-4, 5):
        for s in scale:
            p = root + 12 * o + s
            if best is None or abs(p - pitch) < abs(best - pitch) or (abs(p - pitch) == abs(best - pitch) and p < best):
                best = p
    return best


class Human:
    """Deterministic humanising: small velocity and timing drift."""

    def __init__(self, seed):
        self.r = np.random.default_rng(seed)

    def v(self, vel, spread=7):
        return int(vel + self.r.integers(-spread, spread + 1))

    def t(self, beat, spread=0.012):
        return beat + float(self.r.uniform(-spread, spread)) if beat > 0 else beat


def line(part, h, start, notes, vel=88, blown=False, octave=0):
    """notes: list of (pitch or None, beats). Writes them back to back from start."""
    b = start
    for p, d in notes:
        if p is not None:
            if blown:
                part.blown(h.t(b), d * 0.97, p + octave, h.v(vel))
            else:
                part.note(h.t(b), d * 0.95, p + octave, h.v(vel))
        b += d
    return b


# ---------------------------------------------------------------------------- menu
MENU_BPM, MENU_BEATS = 60, 64


def menu():
    h = Human(11)
    drone_a = Part("drone_a", 0, STRINGS_SLOW, volume=112, reverb=90)
    drone_b = Part("drone_b", 5, STRINGS_SLOW, volume=112, reverb=90)
    koto = Part("koto", 1, KOTO, volume=78, pan=44, reverb=80)
    shaku = Part("shakuhachi", 2, SHAKUHACHI, volume=112, pan=80, reverb=95)
    taiko = Part("odaiko", 3, TAIKO, volume=88, reverb=70)
    # two overlapping drones crossfade so the bowing never restarts audibly at the seam
    for b0, part in ((0, drone_a), (32, drone_b)):
        part.swell(b0, 12, 20, 100)
        part.swell(b0 + 24, 12, 100, 0)
        part.note(b0, 37, D2, 92)
        part.note(b0, 37, D3 - 5, 80)   # A2
    # koto: a few plucks every two bars, like ink drops
    phrases = [
        [(0, D3, 0), (0, D3 + 7, 0), (1.5, deg(IN_SCALE, D4, 1), 0), (2, D4, 0), (3.5, deg(IN_SCALE, D4, -2), 0)],
        [(0, deg(IN_SCALE, D3, 2), 0), (1, deg(IN_SCALE, D4, 2), 0), (2.5, deg(IN_SCALE, D4, 1), 0)],
        [(0, deg(IN_SCALE, D3, -1), 0), (0, deg(IN_SCALE, D3, 3), 0), (2, deg(IN_SCALE, D4, 0), 0),
         (2.5, deg(IN_SCALE, D4, 1), 0), (3, deg(IN_SCALE, D4, 3), 0)],
        [(0, deg(IN_SCALE, D3, 3), 0), (2, deg(IN_SCALE, D4, -1), 0), (3, deg(IN_SCALE, D4, -2), 0)],
    ]
    for bar2 in range(8):
        ph = phrases[bar2 % 4]
        for (b, p, _) in ph:
            koto.note(h.t(bar2 * 8 + b), 3.0, p, h.v(72 if b else 84))
    # shakuhachi: two breaths of melody, long silences between (ma)
    line(shaku, h, 8, [(deg(IN_SCALE, D4, 3), 3), (deg(IN_SCALE, D4, 4), 1), (deg(IN_SCALE, D4, 3), 2),
                       (deg(IN_SCALE, D4, 2), 2), (None, 1), (deg(IN_SCALE, D4, 1), 1.5),
                       (D4, 5.5)], vel=84, blown=True)
    line(shaku, h, 40, [(D5, 3), (deg(IN_SCALE, D4, 6), 0.5), (D5, 0.5), (deg(IN_SCALE, D4, 4), 2),
                        (deg(IN_SCALE, D4, 3), 3), (deg(IN_SCALE, D4, 2), 1), (deg(IN_SCALE, D4, 3), 6)],
         vel=88, blown=True)
    # the red sun: one deep odaiko stroke and a ghost per half
    for b0 in (0, 32):
        taiko.note(b0, 2, D2, 112)
        taiko.note(b0 + 0.75, 1, D2, 52)
    return [drone_a, drone_b, koto, shaku, taiko]


# ---------------------------------------------------------------------------- battle
BATTLE_BPM, BATTLE_BEATS = 128, 160
# bar roots (semitones above D) for sections A1 B A2 C D
_A = [0, 0, -4, -5, 0, 0, 5, 7]
_B = [5, 5, 1, 0, 5, 5, -4, -5]
_C = [-4, -4, -5, -5, 5, 5, 7, 7]
_D = [0, 1, 0, -5, 0, 1, 5, 7]
BATTLE_ROOTS = _A + _B + _A + _C + _D

THEME = [  # shakuhachi theme, 8 bars, degrees of D in-scale around D4
    [(3, 1.5), (2, 0.5), (3, 1), (4, 1)],
    [(3, 3), (None, 1)],
    [(5, 1), (4, 0.5), (3, 0.5), (2, 1), (3, 1)],
    [(1, 2), (0, 2)],
    [(0, 0.5), (1, 0.5), (2, 1), (3, 1.5), (4, 0.5)],
    [(5, 2), (6, 1), (5, 1)],
    [(4, 1), (3, 1), (2, 1), (1, 1)],
    [(0, 3), (None, 1)],
]
KOTO_ANSWER = [  # section B lead, around G
    [(2, 1), (3, 1), (4, 1), (5, 1)],
    [(6, 2), (5, 1), (4, 1)],
    [(3, 1.5), (4, 0.5), (3, 1), (1, 1)],
    [(0, 3), (None, 1)],
    [(2, 0.5), (3, 0.5), (4, 1), (5, 1), (7, 1)],
    [(6, 1), (5, 1), (4, 2)],
    [(3, 1), (2, 1), (1, 1), (-1, 1)],
    [(-2, 3), (None, 1)],
]
CRY = [[(5, 4)], [(6, 2), (5, 2)], [(4, 4)], [(3, 4)], [(2, 4)], [(3, 2), (4, 2)], [(3, 4)], [(3, 4)]]


def _deg_notes(bars, root=D4):
    out = []
    for bar in bars:
        out += [(None if d is None else deg(IN_SCALE, root, d), b) for d, b in bar]
    return out


def battle_base():
    h = Human(23)
    sham = Part("shamisen", 0, SHAMISEN, volume=127, pan=50, reverb=35)
    koto = Part("koto", 1, KOTO, volume=96, pan=84, reverb=45)
    shaku = Part("shakuhachi", 2, SHAKUHACHI, volume=92, pan=64, reverb=60)
    taiko = Part("taiko", 3, TAIKO, volume=118, reverb=40)
    shime = Part("shime", 4, MELODIC_TOM, volume=96, pan=74, reverb=25)
    perc = Part("hyoshigi", 9, None, volume=108, reverb=30)
    for bar, r in enumerate(BATTLE_ROOTS):
        b0 = bar * 4
        root = D3 + r
        section = bar // 8
        # shamisen: the bachi strikes eighths; on section D it doubles into sixteenths
        pat = [0, 12, 7, 12, 0, 7, 12, 7]
        if section == 4 and bar % 2 == 1:
            for k in range(16):
                p = snap(root + [0, 12, 7, 12][k % 4] + (1 if k >= 12 else 0))
                sham.note(b0 + k * 0.25, 0.22, p, h.v(96 if k % 4 == 0 else 74))
        else:
            for k, iv in enumerate(pat):
                p = snap(root + iv)
                sham.note(h.t(b0 + k * 0.5), 0.42, p, h.v(104 if k in (0, 3) else 78))
        # koto off-beat dyads under the A sections, arpeggio in C
        if section in (0, 2, 4):
            for off in (0.5, 2.5):
                koto.note(h.t(b0 + off), 0.4, snap(root + 12), h.v(70))
                koto.note(h.t(b0 + off), 0.4, snap(root + 19), h.v(62))
        elif section == 3:
            for k in range(8):
                koto.note(h.t(b0 + k * 0.5), 0.6, snap(root + [12, 19, 24, 19][k % 4]), h.v(66))
        # light skeleton: low taiko 1 & 3, hyoshigi 2 & 4, shime eighths
        taiko.note(b0, 1, D2 + 7, h.v(92))
        taiko.note(b0 + 2, 1, D2 + 7, h.v(80))
        perc.note(b0 + 1, 0.2, WOOD_HI, h.v(76))
        perc.note(b0 + 3, 0.2, WOOD_LO, h.v(80))
        for k in range(8):
            shime.note(b0 + k * 0.5, 0.2, 69, h.v(80 if k % 2 == 0 else 52, 5))
    # melodies
    line(shaku, h, 0, _deg_notes(THEME), vel=96, blown=True)
    line(koto, h, 32, _deg_notes(KOTO_ANSWER, D4), vel=96)
    line(shaku, h, 64, _deg_notes(THEME), vel=100, blown=True)
    line(shaku, h, 96, _deg_notes(CRY, D4), vel=104, blown=True)
    return [sham, koto, shaku, taiko, shime, perc]


def battle_war():
    h = Human(31)
    taiko = Part("taiko_ens", 3, TAIKO, volume=118, reverb=45)
    oda = Part("odaiko", 6, TAIKO, volume=120, reverb=55)
    shime = Part("shime16", 4, MELODIC_TOM, volume=84, pan=40, reverb=25)
    fue = Part("shinobue", 5, PICCOLO, volume=78, pan=70, reverb=60)
    kit = Part("drums", 9, None, volume=96, reverb=35)
    don = [0, 3, 4, 6, 7, 8, 11, 12, 14]          # don . . do kon . doko don . . do kon . do .
    for bar in range(BATTLE_BEATS // 4):
        b0 = bar * 4
        section = bar // 8
        for k in don:
            taiko.note(h.t(b0 + k * 0.25, 0.006), 0.3, 45 if k % 4 else 43, h.v(108 if k % 4 == 0 else 84))
        oda.note(b0, 1.5, D2 - 2, h.v(116))
        if section >= 3 or bar % 2 == 1:
            oda.note(b0 + 2.5, 1.0, D2 - 2, h.v(96))
        kit.note(b0, 0.5, KICK, h.v(96))
        kit.note(b0 + 2, 0.5, KICK, h.v(84))
        for k in range(16):
            shime.note(b0 + k * 0.25, 0.15, 72, h.v(96 if k % 4 == 0 else 58, 6))
        if bar % 8 == 0:
            kit.note(b0, 1.0, CHINA, h.v(92))
        if bar % 2 == 1:  # roll into the next bar
            for k in range(4):
                kit.note(b0 + 3 + k * 0.25, 0.2, FLOOR_LO if k < 2 else FLOOR_HI, h.v(84 + 6 * k))
        if bar % 4 == 3:
            kit.note(b0 + 3.5, 0.3, CLAVES, h.v(90))
    # shinobue doubles the theme an octave up in A2 and the cry in C
    line(fue, h, 64, _deg_notes(THEME, D5), vel=84)
    line(fue, h, 96, _deg_notes(CRY, D5), vel=80)
    return [taiko, oda, shime, fue, kit]


# ---------------------------------------------------------------------------- boss
BOSS_BPM, BOSS_BEATS = 140, 144
BOSS_ROOTS = ([0] * 4 + [0, 0, 1, 0, 6, 6, 5, 1] + [0, 1, 6, 5, 0, 1, 10 - 12, 1]
              + [6, 6, 5, 5, 1, 1, 0, 0] + [0, 1, 0, 6, 0, 1, 5, 1])
REED = [[(5, 2), (4, 1), (3, 1)], [(2, 3), (1, 1)], [(0, 1.5), (1, 0.5), (2, 1), (3, 1)], [(2, 4)],
        [(3, 2), (4, 1), (5, 1)], [(6, 2), (5, 1), (4, 1)], [(3, 1), (2, 1), (1, 1), (2, 1)], [(0, 4)]]
SCREAM = [[(10, 4)], [(9, 2), (10, 2)], [(8, 4)], [(7, 4)], [(10, 3), (11, 1)], [(10, 4)], [(9, 2), (8, 2)], [(7, 4)]]


def _iwato(bars, root):
    out = []
    for bar in bars:
        out += [(None if d is None else deg(IWATO, root, d), b) for d, b in bar]
    return out


def boss():
    h = Human(47)
    sham = Part("shamisen", 0, SHAMISEN, volume=104, pan=46, reverb=30)
    koto = Part("koto", 1, KOTO, volume=90, pan=86, reverb=45)
    reed = Part("hichiriki", 2, SHANAI, volume=88, pan=64, reverb=55)
    shaku = Part("shakuhachi", 7, SHAKUHACHI, volume=108, pan=70, reverb=60)
    taiko = Part("taiko", 3, TAIKO, volume=120, reverb=45)
    shime = Part("shime", 4, MELODIC_TOM, volume=84, pan=36, reverb=25)
    timp = Part("timpani", 5, TIMPANI, volume=80, reverb=50)
    kit = Part("drums", 9, None, volume=96, reverb=35)
    for bar, r in enumerate(BOSS_ROOTS):
        b0 = bar * 4
        root = D3 + r
        section = 0 if bar < 4 else 1 + (bar - 4) // 8
        for k in range(16):  # shamisen tremolo-ostinato in sixteenths
            iv = [0, 0, 12, 0, 6, 0, 12, 13][k % 8] if section != 3 else [0, 12][k % 2]
            sham.note(b0 + k * 0.25, 0.2, snap(root + iv, IWATO), h.v(100 if k % 4 == 0 else 70))
        heavy = section in (2, 4)
        for k in range(4):
            taiko.note(h.t(b0 + k, 0.005), 0.8, D2 - 2, h.v(118 if k == 0 else (104 if heavy else 84)))
        for k in (3, 6, 7, 11, 14, 15) if heavy else (6, 14):
            taiko.note(b0 + k * 0.25, 0.3, 45, h.v(96))
        for k in range(16):
            shime.note(b0 + k * 0.25, 0.15, 72, h.v(100 if k % 4 == 0 else 60, 6))
        kit.note(b0, 0.5, KICK, h.v(110))
        kit.note(b0 + 2, 0.5, KICK, h.v(96))
        if bar % 4 == 0:
            kit.note(b0, 1.0, CHINA, h.v(100))
        if section == 3 and bar % 2 == 0:  # koto glissando breaks
            for k in range(8):
                koto.note(b0 + k * 0.125, 1.0, deg(IWATO, D4, k - 2), h.v(70 + 4 * k))
        if bar % 8 == 3:  # timpani roll into each section
            for k in range(16):
                timp.note(b0 + k * 0.25, 0.25, D2 + 12 - 12, h.v(60 + 3 * k))
    line(reed, h, 16, _iwato(REED, D4), vel=96, blown=True)
    line(shaku, h, 48, _iwato(SCREAM, D4 - 12), vel=110, blown=True)
    line(reed, h, 112, _iwato(REED, D4), vel=100, blown=True)
    line(shaku, h, 112, _iwato(REED, D5 - 12), vel=96, blown=True)
    return [sham, koto, reed, shaku, taiko, shime, timp, kit]


# ---------------------------------------------------------------------------- game over
GAMEOVER_BPM, GAMEOVER_BEATS = 60, 14


def gameover():
    h = Human(59)
    shaku = Part("shakuhachi", 2, SHAKUHACHI, volume=104, reverb=100)
    koto = Part("koto", 1, KOTO, volume=96, pan=44, reverb=90)
    taiko = Part("odaiko", 3, TAIKO, volume=96, reverb=80)
    drone = Part("drone", 0, STRINGS_SLOW, volume=110, reverb=100)
    taiko.note(0, 2, D2, 120)
    taiko.note(0.5, 1, D2, 60)
    drone.swell(0, 3, 30, 100)
    drone.swell(7, 5, 100, 0)
    drone.note(0, 12, D2, 70)
    drone.note(0, 12, D2 + 7, 55)
    line(shaku, h, 1, [(deg(IN_SCALE, D4, 3), 2), (deg(IN_SCALE, D4, 2), 1), (deg(IN_SCALE, D4, 1), 1.5),
                       (D4, 5)], vel=92, blown=True)
    koto.note(4, 4, D3, 80)
    koto.note(4.05, 4, D3 + 7, 70)
    koto.note(9, 4, D2 + 12, 76)
    return [drone, shaku, koto, taiko]
