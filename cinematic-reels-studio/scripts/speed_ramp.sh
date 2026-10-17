#!/usr/bin/env bash
# Usage: speed_ramp.sh <in.mp4> <out.mp4> <ramp_start_s> <ramp_end_s> [min_speed=0.3] [steps=10]
# Eased speed ramp 1x -> min_speed -> 1x between start and end (smoothstep), built from short
# segments so the change is gradual. Video only (rebuild audio from the beat map, not from this).
# For smooth slow-mo on clean motion, shoot 60 fps or add minterpolate afterwards.
set -eu
IN="${1:?in}"; OUT="${2:?out}"; S="${3:?start}"; E="${4:?end}"; MIN="${5:-0.3}"; N="${6:-10}"
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$IN")
FC="[0:v]trim=0:${S},setpts=PTS-STARTPTS[pre];"
LABELS="[pre]"
SEG=$(awk -v s="$S" -v e="$E" -v n="$N" 'BEGIN{printf "%.5f",(e-s)/n}')
for ((i=0; i<N; i++)); do
  a=$(awk -v s="$S" -v g="$SEG" -v i="$i" 'BEGIN{printf "%.5f", s+g*i}')
  b=$(awk -v s="$S" -v g="$SEG" -v i="$i" 'BEGIN{printf "%.5f", s+g*(i+1)}')
  # bell curve 0..1..0 (sin^2) -> speed goes 1 -> MIN -> 1
  sp=$(awk -v i="$i" -v n="$N" -v m="$MIN" 'BEGIN{pi=3.14159265; x=(i+0.5)/n; k=sin(pi*x); k=k*k; printf "%.4f", 1-(1-m)*k}')
  pts=$(awk -v sp="$sp" 'BEGIN{printf "%.5f", 1/sp}')
  FC="${FC}[0:v]trim=${a}:${b},setpts=(PTS-STARTPTS)*${pts}[s${i}];"
  LABELS="${LABELS}[s${i}]"
done
FC="${FC}[0:v]trim=${E}:${DUR},setpts=PTS-STARTPTS[post];"
LABELS="${LABELS}[post]"
FC="${FC}${LABELS}concat=n=$((N+2)):v=1:a=0[v]"
ffmpeg -v error -y -i "$IN" -filter_complex "$FC" -map "[v]" -c:v libx264 -preset "${PRESET:-slow}" -crf 16 -pix_fmt yuv420p -an "$OUT"
echo "ramped: $OUT"
