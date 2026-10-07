"""Tiny score toolkit: write notes in beats, export General MIDI with mido.

A Part is one MIDI channel with one GM program. Times are in beats (quarter notes). Every loop
is written once and repeated by render.py, so the seam is cut from the middle repetition.
"""
import mido

TPB = 480

# GM programs (0-based)
SHAKUHACHI, KOTO, SHAMISEN, TAIKO, MELODIC_TOM, WOODBLOCK = 77, 107, 106, 116, 117, 115
SHANAI, TIMPANI, STRINGS_SLOW, CONTRABASS, PICCOLO, TUBULAR = 111, 47, 49, 43, 72, 14
PAD_BOWED, PIZZ, CELLO = 92, 45, 42

# GM percussion keys (channel 10)
KICK, FLOOR_LO, FLOOR_HI, TOM_LO, TOM_MID, TOM_HI = 36, 41, 43, 45, 47, 50
WOOD_HI, WOOD_LO, CLAVES, CHINA, SPLASH = 76, 77, 75, 52, 55

# D in (miyako-bushi) and D iwato, as semitone offsets
IN_SCALE = [0, 1, 5, 7, 8]
IWATO = [0, 1, 5, 6, 10]


def deg(scale, root, d):
    """Scale degree d (may be negative / beyond one octave) above MIDI root."""
    octv, i = divmod(d, len(scale))
    return root + 12 * octv + scale[i]


class Part:
    def __init__(self, name, channel, program=None, volume=100, pan=64, reverb=40):
        self.name, self.channel, self.program = name, channel, program
        self.volume, self.pan, self.reverb = volume, pan, reverb
        self.events = []  # (beat, order, mido.Message)

    def note(self, beat, dur, pitch, vel=90):
        vel = max(1, min(127, int(vel)))
        self.events.append((beat, 1, mido.Message("note_on", channel=self.channel, note=pitch, velocity=vel)))
        self.events.append((beat + dur, 0, mido.Message("note_off", channel=self.channel, note=pitch, velocity=0)))

    def bend(self, beat, semis, rng=2.0):
        v = int(max(-8192, min(8191, semis / rng * 8192)))
        self.events.append((beat, 0, mido.Message("pitchwheel", channel=self.channel, pitch=v)))

    def glide(self, beat, dur, s0, s1, steps=8):
        for k in range(steps + 1):
            self.bend(beat + dur * k / steps, s0 + (s1 - s0) * k / steps)

    def cc(self, beat, ctrl, value):
        self.events.append((beat, 0, mido.Message("control_change", channel=self.channel,
                                                  control=ctrl, value=max(0, min(127, int(value))))))

    def swell(self, beat, dur, v0, v1, steps=12):
        for k in range(steps + 1):
            self.cc(beat + dur * k / steps, 11, v0 + (v1 - v0) * k / steps)

    def blown(self, beat, dur, pitch, vel=90, meri=-1.0, swell=(70, 115)):
        """Shakuhachi-style note: scoop up from below (meri), breath swell, settle."""
        self.bend(beat - 0.01, meri)
        self.glide(beat, min(0.35, dur * 0.4), meri, 0.0, 6)
        if dur >= 1.0:
            self.swell(beat, dur * 0.7, swell[0], swell[1], 8)
            self.swell(beat + dur * 0.7, dur * 0.3, swell[1], swell[0] - 10, 4)
        else:
            self.cc(beat, 11, swell[1])
        self.note(beat, dur, pitch, vel)


def write_midi(path, parts, bpm, repeats, loop_beats, tail_beats=8):
    """Writes the parts, repeated `repeats` times back to back, plus silence for the tail."""
    mid = mido.MidiFile(type=1, ticks_per_beat=TPB)
    meta = mido.MidiTrack()
    meta.append(mido.MetaMessage("set_tempo", tempo=mido.bpm2tempo(bpm), time=0))
    end_tick = int((loop_beats * repeats + tail_beats) * TPB)
    meta.append(mido.MetaMessage("end_of_track", time=end_tick))
    mid.tracks.append(meta)
    for p in parts:
        tr = mido.MidiTrack()
        setup = []
        if p.program is not None:
            setup.append(mido.Message("program_change", channel=p.channel, program=p.program))
        setup += [mido.Message("control_change", channel=p.channel, control=7, value=p.volume),
                  mido.Message("control_change", channel=p.channel, control=10, value=p.pan),
                  mido.Message("control_change", channel=p.channel, control=91, value=p.reverb),
                  mido.Message("control_change", channel=p.channel, control=93, value=0),
                  mido.Message("control_change", channel=p.channel, control=11, value=110)]
        evs = []
        for r in range(repeats):
            off = r * loop_beats
            for (b, o, m) in p.events:
                evs.append((int(round((b + off) * TPB)), o, m))
        evs.sort(key=lambda e: (e[0], e[1]))
        last = 0
        for m in setup:
            tr.append(m.copy(time=0))
        for (tick, _, m) in evs:
            tick = max(tick, 0)
            tr.append(m.copy(time=tick - last))
            last = tick
        tr.append(mido.MetaMessage("end_of_track", time=max(0, end_tick - last)))
        mid.tracks.append(tr)
    mid.save(path)
