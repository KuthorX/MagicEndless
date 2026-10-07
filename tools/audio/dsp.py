"""Shared synthesis primitives for the War Grimoire sound set (numpy/scipy only).

Every sound is built from a few physical metaphors: a struck block of wood (modal resonator),
a plucked silk string (Karplus-Strong), a skin drum (pitch-dropping sine + slap), brushed paper
(band-limited noise) and a bronze rin bowl (long inharmonic partials).
"""
import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100


def t_axis(dur):
    return np.arange(int(dur * SR)) / SR


def env_exp(dur, decay, attack=0.002):
    t = t_axis(dur)
    a = np.clip(t / max(attack, 1e-5), 0.0, 1.0)
    return a * np.exp(-t / decay)


def env_ar(dur, attack, release_from):
    """Linear attack, flat, then cosine release starting at release_from seconds."""
    t = t_axis(dur)
    a = np.clip(t / max(attack, 1e-5), 0.0, 1.0)
    r = np.ones_like(t)
    m = t > release_from
    span = max(dur - release_from, 1e-4)
    r[m] = 0.5 + 0.5 * np.cos(np.pi * np.clip((t[m] - release_from) / span, 0, 1))
    return a * r


def noise(dur, rng):
    return rng.standard_normal(int(dur * SR))


def bandpass(x, lo, hi, order=2):
    sos = signal.butter(order, [lo, min(hi, SR / 2 - 100)], btype="band", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def lowpass(x, f, order=2):
    sos = signal.butter(order, min(f, SR / 2 - 100), btype="low", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def highpass(x, f, order=2):
    sos = signal.butter(order, f, btype="high", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def swept_band(x, f_start, f_end, q=3.0, block=256):
    """Time-varying band-pass (block-wise state-variable filter) for brush/whoosh sweeps."""
    out = np.zeros_like(x)
    n = len(x)
    low = band = 0.0
    for i0 in range(0, n, block):
        frac = i0 / max(n - 1, 1)
        fc = f_start * (f_end / f_start) ** frac
        f = 2.0 * np.sin(np.pi * min(fc, SR / 6) / SR)
        damp = 1.0 / q
        seg = x[i0:i0 + block]
        res = np.empty_like(seg)
        for j, v in enumerate(seg):
            low += f * band
            high = v - low - damp * band
            band += f * high
            res[j] = band
        out[i0:i0 + block] = res
    return out


def sine_sweep(dur, f0, f1, curve=8.0):
    t = t_axis(dur)
    f = f1 + (f0 - f1) * np.exp(-t * curve)
    return np.sin(2 * np.pi * np.cumsum(f) / SR)


def modal(dur, freqs, decays, amps):
    """Struck object: sum of exponentially damped sinusoids."""
    t = t_axis(dur)
    out = np.zeros_like(t)
    for f, d, a in zip(freqs, decays, amps):
        if f < SR / 2:
            out += a * np.sin(2 * np.pi * f * t) * np.exp(-t / d)
    return out


def wood(dur, f0, rng, brightness=1.0):
    """Hyoshigi / woodblock: few strongly damped inharmonic modes plus a click."""
    ratios = [1.0, 2.57, 4.21, 6.3]
    body = modal(dur, [f0 * r for r in ratios], [0.045, 0.02, 0.011, 0.007],
                 [1.0, 0.5 * brightness, 0.28 * brightness, 0.15 * brightness])
    click = highpass(noise(dur, rng), 2500) * env_exp(dur, 0.002)
    return body + 0.35 * brightness * click


def rin(dur, f0, decay=1.2):
    """Bronze rin bowl: slightly beating inharmonic partials with long tails."""
    ratios = [1.0, 1.006, 2.74, 2.752, 5.02, 8.1]
    amps = [1.0, 0.7, 0.45, 0.3, 0.18, 0.08]
    decays = [decay, decay * 0.9, decay * 0.5, decay * 0.45, decay * 0.25, decay * 0.12]
    return modal(dur, [f0 * r for r in ratios], decays, amps)


def drum(dur, f_hi, f_lo, decay, rng, slap=0.4, curve=30.0):
    """Taiko-like membrane: sine dropping in pitch, a skin slap, a little body noise."""
    body = sine_sweep(dur, f_hi, f_lo, curve) * env_exp(dur, decay, 0.001)
    sl = lowpass(noise(dur, rng), 1800) * env_exp(dur, 0.012)
    return body + slap * sl


def pluck(dur, freq, rng, damping=0.996, bright=0.6):
    """Karplus-Strong silk string (koto / shamisen colour)."""
    n = int(dur * SR)
    period = max(2, int(SR / freq))
    buf = rng.uniform(-1, 1, period)
    buf = lowpass(buf, 1500 + 7000 * bright, 1)
    out = np.zeros(n)
    idx = 0
    for i in range(n):
        v = buf[idx]
        nxt = buf[(idx + 1) % period]
        buf[idx] = damping * 0.5 * (v + nxt)
        out[i] = v
        idx = (idx + 1) % period
    return out


def fm(dur, fc, ratio, index, decay):
    t = t_axis(dur)
    e = np.exp(-t / decay)
    return np.sin(2 * np.pi * fc * t + index * e * np.sin(2 * np.pi * fc * ratio * t)) * e


def place(dst, src, at):
    i = int(at * SR)
    end = min(len(dst), i + len(src))
    dst[i:end] += src[:end - i]
    return dst


def room(x, mix=0.12, size=0.06):
    """Tiny dry room (a few early reflections). SFX stay dry on purpose."""
    out = x.copy()
    for k, (d, g) in enumerate([(0.011, 0.5), (0.019, 0.35), (0.029, 0.25), (size, 0.15)]):
        i = int(d * SR)
        out[i:] += mix * g * x[:-i]
    return out


def _biquad(b, a, x):
    return signal.lfilter(b, a, x)


def k_weight(x):
    """ITU-R BS.1770 K-weighting (RBJ high shelf +4 dB @1681 Hz, high-pass @38 Hz)."""
    w0 = 2 * np.pi * 1681.97 / SR
    A = 10 ** (3.99984 / 40)
    alpha = np.sin(w0) / (2 * 0.7071752)
    cw = np.cos(w0)
    b = [A * ((A + 1) + (A - 1) * cw + 2 * np.sqrt(A) * alpha), -2 * A * ((A - 1) + (A + 1) * cw),
         A * ((A + 1) + (A - 1) * cw - 2 * np.sqrt(A) * alpha)]
    a = [(A + 1) - (A - 1) * cw + 2 * np.sqrt(A) * alpha, 2 * ((A - 1) - (A + 1) * cw),
         (A + 1) - (A - 1) * cw - 2 * np.sqrt(A) * alpha]
    y = _biquad(b, a, x)
    w1 = 2 * np.pi * 38.135 / SR
    al = np.sin(w1) / (2 * 0.5003)
    c1 = np.cos(w1)
    b2 = [(1 + c1) / 2, -(1 + c1), (1 + c1) / 2]
    a2 = [1 + al, -2 * c1, 1 - al]
    return _biquad(b2, a2, y)


def loudness(x, window=0.4):
    """Loudest 400 ms window (max momentary LUFS) - the level a player perceives for a hit."""
    y = k_weight(x) ** 2
    n = int(window * SR)
    if len(y) <= n:
        return -0.691 + 10 * np.log10(np.sum(y) / n + 1e-12)
    c = np.cumsum(np.concatenate([[0.0], y]))
    ms = (c[n:] - c[:-n]) / n
    return -0.691 + 10 * np.log10(np.max(ms) + 1e-12)


def finish(x, lufs=-24.0, peak_db=-1.5, fade_in=0.001, fade_out=0.012, soft_db=4.0):
    """Normalise to a momentary loudness target, soft-limit at most soft_db into the ceiling."""
    x = x - np.mean(x)
    fi = max(1, int(fade_in * SR))
    fo = max(1, int(fade_out * SR))
    x[:fi] *= np.linspace(0, 1, fi)
    x[-fo:] *= np.linspace(1, 0, fo) ** 2
    x = x * 10 ** ((lufs - loudness(x)) / 20)
    lim = 10 ** (peak_db / 20)
    pk = np.max(np.abs(x))
    over_db = 20 * np.log10(pk / lim) if pk > 0 else 0
    if over_db > soft_db:
        x = x * 10 ** (-(over_db - soft_db) / 20)
    if np.max(np.abs(x)) > lim * 0.5:
        knee = lim * 0.5
        a = np.abs(x)
        m = a > knee
        x[m] = np.sign(x[m]) * (knee + (lim - knee) * np.tanh((a[m] - knee) / (lim - knee)))
    return x


def write(path, x):
    wavfile.write(path, SR, (np.clip(x, -1, 1) * 32767).astype(np.int16))
