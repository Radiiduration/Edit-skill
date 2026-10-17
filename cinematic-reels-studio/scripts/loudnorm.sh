#!/usr/bin/env bash
# Usage: loudnorm.sh <in.mp4> <out.mp4> [target_LUFS=-14] [true_peak=-1.5]
# Two-pass EBU R128 normalisation. Video stream is copied untouched.
set -eu
IN="${1:?input}"; OUT="${2:?output}"; I="${3:--14}"; TP="${4:--1.5}"
J=$(ffmpeg -hide_banner -nostats -i "$IN" -af "loudnorm=I=${I}:TP=${TP}:LRA=11:print_format=json" -vn -f null - 2>&1 | sed -n '/^{/,/^}/p')
get() { echo "$J" | grep "\"$1\"" | head -1 | sed 's/.*: *"\{0,1\}\([-0-9.inf]*\)"\{0,1\},\{0,1\}/\1/'; }
MI=$(get input_i); MTP=$(get input_tp); MLRA=$(get input_lra); MT=$(get input_thresh); OFF=$(get target_offset)
[ -n "$MI" ] || { echo "could not measure loudness (no audio?)" >&2; exit 1; }
ffmpeg -v error -y -i "$IN" -c:v copy \
  -af "loudnorm=I=${I}:TP=${TP}:LRA=11:measured_I=${MI}:measured_TP=${MTP}:measured_LRA=${MLRA}:measured_thresh=${MT}:offset=${OFF}:linear=true,aresample=48000" \
  -c:a aac -b:a 256k -movflags +faststart "$OUT"
echo "normalised: $OUT (measured ${MI} LUFS -> target ${I})"
