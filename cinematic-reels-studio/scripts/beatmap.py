#!/usr/bin/env python3
"""Build a beat map for an audio/video file.

Usage: beatmap.py <audio-or-video> [out.json]

Writes .studio/beatmap.json style output: bpm, beats, downbeats, onsets, drop candidates (seconds).
Uses librosa when installed (best), otherwise a numpy-only spectral-flux fallback that decodes
through ffmpeg. Treat results as a draft: cuts and drops should still be sanity-checked by a human
listening to the track (Claude cannot hear audio).
"""
import json
import subprocess
import sys

import numpy as np

SR = 22050
HOP = 256
NFFT = 1024
# Frame time convention: centre of the analysis window.
LAG = NFFT / 2 / SR


def decode(path):
    cmd = ["ffmpeg", "-v", "error", "-i", path, "-vn", "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"]
    raw = subprocess.run(cmd, check=True, stdout=subprocess.PIPE).stdout
    return np.frombuffer(raw, dtype=np.float32)


def onset_envelope(y):
    win = np.hanning(NFFT).astype(np.float32)
    n = 1 + (len(y) - NFFT) // HOP
    if n < 8:
        raise SystemExit("audio too short to analyse")
    frames = np.lib.stride_tricks.sliding_window_view(y, NFFT)[::HOP][:n] * win
    mag = np.abs(np.fft.rfft(frames, axis=1))
    logm = np.log1p(10.0 * mag)
    flux = np.maximum(0.0, np.diff(logm, axis=0)).sum(axis=1)
    flux = np.concatenate([[0.0], flux])
    flux -= flux.min()
    return flux / (flux.max() + 1e-9)


def estimate_tempo(env, fps):
    e = env - env.mean()
    ac = np.correlate(e, e, mode="full")[len(e) - 1:]
    lo, hi = int(fps * 60 / 180), int(fps * 60 / 70)
    lags = np.arange(lo, hi)
    # mild prior towards 100-150 BPM so we do not pick half/double time
    bpm_c = 60.0 * fps / lags
    prior = np.exp(-0.5 * ((np.log2(bpm_c / 120.0)) / 0.6) ** 2)
    best = lags[np.argmax(ac[lo:hi] * prior)]
    return 60.0 * fps / best, best


def refine_grid(env, fps, bpm0):
    """Fine-search tempo (+-4%) and phase so a regular grid sits on the onset peaks (constant-tempo assumption)."""
    x = np.arange(len(env))
    best = (-1.0, bpm0, 0.0)
    for bpm in np.arange(bpm0 * 0.96, bpm0 * 1.04, 0.05):
        period = 60.0 * fps / bpm
        for ph in np.arange(0.0, period, 0.5):
            pos = np.arange(ph, len(env) - 1, period)
            score = np.interp(pos, x, env).mean()
            if score > best[0]:
                best = (score, float(bpm), float(ph))
    return best[1], best[2]


def fallback(y):
    env = onset_envelope(y)
    fps = SR / HOP
    bpm0, _ = estimate_tempo(env, fps)
    bpm, phase = refine_grid(env, fps, bpm0)
    period = 60.0 * fps / bpm
    beats = (np.arange(phase, len(env) - 1, period) / fps) + LAG
    # downbeat = phase of 4 with the most onset energy
    x = np.arange(len(env))
    scores = [np.interp((beats[p::4] - LAG) * fps, x, env).sum() for p in range(4)]
    dp = int(np.argmax(scores))
    downbeats = beats[dp::4]
    # onsets = peaks above adaptive threshold
    thr = env.mean() + 1.2 * env.std()
    pk = [i for i in range(1, len(env) - 1) if env[i] > thr and env[i] >= env[i - 1] and env[i] > env[i + 1]]
    onsets, last = [], -1.0
    for i in pk:
        t = i / fps + LAG
        if t - last > 0.08:
            onsets.append(t)
            last = t
    return float(bpm), beats.tolist(), downbeats.tolist(), onsets


def with_librosa(y):
    import librosa

    tempo, beat_frames = librosa.beat.beat_track(y=y, sr=SR, hop_length=HOP, units="frames")
    beats = librosa.frames_to_time(beat_frames, sr=SR, hop_length=HOP)
    onsets = librosa.onset.onset_detect(y=y, sr=SR, hop_length=HOP, units="time", backtrack=False)
    env = librosa.onset.onset_strength(y=y, sr=SR, hop_length=HOP)
    fps = SR / HOP
    scores = [env[np.clip((beats[p::4] * fps).astype(int), 0, len(env) - 1)].sum() for p in range(4)]
    dp = int(np.argmax(scores)) if len(beats) >= 4 else 0
    return float(np.atleast_1d(tempo)[0]), beats.tolist(), beats[dp::4].tolist(), onsets.tolist()


def drop_candidates(y, k=3):
    """Largest sustained loudness jumps: mean RMS of next 1 s vs previous 2 s."""
    w = int(SR * 0.25)
    n = len(y) // w
    if n < 12:
        return []
    rms = np.sqrt((y[: n * w].reshape(n, w) ** 2).mean(axis=1)) + 1e-6
    out = []
    for i in range(8, n - 4):
        prev, nxt = rms[i - 8 : i].mean(), rms[i : i + 4].mean()
        out.append((nxt / prev, i * 0.25))
    out.sort(reverse=True)
    picks = []
    for ratio, t in out:
        if ratio < 1.5:
            break
        if all(abs(t - p["time"]) > 4 for p in picks):
            picks.append({"time": round(t, 2), "loudness_ratio": round(float(ratio), 2)})
        if len(picks) >= k:
            break
    return picks


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    path = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else None
    y = decode(path)
    try:
        method = "librosa"
        bpm, beats, downbeats, onsets = with_librosa(y)
    except Exception:  # librosa missing or failed -> numpy fallback
        method = "numpy-spectral-flux"
        bpm, beats, downbeats, onsets = fallback(y)
    result = {
        "source": path,
        "method": method,
        "duration": round(len(y) / SR, 3),
        "bpm": round(bpm, 2),
        "beat_period": round(60.0 / bpm, 4),
        "beats": [round(t, 3) for t in beats],
        "downbeats": [round(t, 3) for t in downbeats],
        "onsets": [round(t, 3) for t in onsets],
        "drop_candidates": drop_candidates(y),
        "note": "draft: confirm drops/sections by ear; Claude cannot hear audio",
    }
    text = json.dumps(result, indent=2)
    if out:
        with open(out, "w") as f:
            f.write(text)
        print(f"wrote {out}: {result['bpm']} BPM, {len(beats)} beats, {len(downbeats)} downbeats, method={method}")
    else:
        print(text)


if __name__ == "__main__":
    main()
