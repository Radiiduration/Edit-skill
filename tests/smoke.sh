#!/usr/bin/env bash
# Smoke test for cinematic-reels-studio scripts. Needs ffmpeg, ffprobe, python3 + numpy.
# Usage: tests/smoke.sh
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S="$ROOT/cinematic-reels-studio/scripts"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
export PRESET=ultrafast
step() { echo "--- $*"; }
need() { [ -s "$1" ] || { echo "FAIL: missing $1" >&2; exit 1; }; }

step "generate fixtures"
for i in 1 2 3; do
  ffmpeg -v error -y -f lavfi -i "testsrc2=s=1080x1920:r=30:d=3" -f lavfi -i "sine=f=$((220*i)):d=3" \
    -c:v libx264 -preset ultrafast -pix_fmt yuv420p -c:a aac -shortest "$T/c$i.mp4"
done
ffmpeg -v error -y -f lavfi -i "aevalsrc='sin(2*PI*55*mod(t,0.5))*exp(-18*mod(t,0.5))*(0.25+0.75*gt(t,8))':s=44100:d=16" "$T/kick.wav"

step "doctor"
"$S/doctor.sh" > "$T/doctor.txt"; grep -q "ffmpeg" "$T/doctor.txt"

step "beatmap (expect ~120 BPM)"
python3 "$S/beatmap.py" "$T/kick.wav" "$T/bm.json" > /dev/null
python3 - "$T/bm.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
assert 118 <= d["bpm"] <= 122, d["bpm"]
assert len(d["beats"]) >= 28, len(d["beats"])
assert d["drop_candidates"] and abs(d["drop_candidates"][0]["time"] - 8.0) < 1.0, d["drop_candidates"]
print("beatmap ok:", d["bpm"], "BPM")
PY

step "xfade_chain"
"$S/xfade_chain.sh" "$T/joined.mp4" 0.4 slideleft,circleopen "$T/c1.mp4" "$T/c2.mp4" "$T/c3.mp4" > /dev/null
D=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$T/joined.mp4")
awk -v d="$D" 'BEGIN{exit !(d>8.1 && d<8.4)}' || { echo "FAIL: joined duration $D (expected ~8.2)" >&2; exit 1; }

step "speed_ramp"
"$S/speed_ramp.sh" "$T/c1.mp4" "$T/ramp.mp4" 0.8 2.2 0.3 6 > /dev/null; need "$T/ramp.mp4"

step "grade (all looks, 1 s each)"
ffmpeg -v error -y -i "$T/c1.mp4" -t 1 -c copy "$T/short.mp4"
for look in teal-orange moody-night warm-film clean-crisp bleach-lite; do
  "$S/grade.sh" "$T/short.mp4" "$T/g_$look.mp4" "$look" > /dev/null; need "$T/g_$look.mp4"
done

step "loudnorm + verify (pass case)"
ffmpeg -v error -y -f lavfi -i "testsrc2=s=1080x1920:r=30:d=8" -f lavfi -i "sine=f=300:d=8" \
  -c:v libx264 -preset ultrafast -pix_fmt yuv420p -c:a aac -shortest "$T/ok_raw.mp4"
"$S/loudnorm.sh" "$T/ok_raw.mp4" "$T/ok.mp4" -14 -1.5 > /dev/null
"$S/verify.sh" "$T/ok.mp4" "$T/qc_ok" > /dev/null || { cat "$T/qc_ok/report.txt" >&2; echo "FAIL: verify should pass" >&2; exit 1; }

step "verify (fail case must exit non-zero)"
ffmpeg -v error -y -f lavfi -i "testsrc2=s=720x1280:r=25:d=8" -f lavfi -i "sine=f=300:d=8" \
  -c:v libx264 -preset ultrafast -pix_fmt yuv420p -c:a aac -shortest "$T/bad.mp4"
if "$S/verify.sh" "$T/bad.mp4" "$T/qc_bad" > /dev/null 2>&1; then echo "FAIL: verify should fail on 720p/25fps" >&2; exit 1; fi

echo "ALL SMOKE TESTS PASSED"
