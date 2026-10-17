#!/usr/bin/env bash
# Usage: xfade_chain.sh <out.mp4> <xfade_seconds> <transitions_csv> <clip1> <clip2> [clip3 ...]
# Joins same-size, same-fps clips with ffmpeg xfade, computing offsets for you. Video only.
# transitions_csv: one name per join (cycled if shorter). Good cinematic set:
#   slideleft,smoothleft,zoomin,circleopen,wipeleft,fadeblack,radial,hlslice,squeezeh,fadewhite
# Time on the output timeline: each join shortens the total by <xfade_seconds>.
set -eu
OUT="${1:?out}"; XD="${2:?xfade seconds}"; TR="${3:?transitions}"; shift 3
[ "$#" -ge 2 ] || { echo "need at least 2 clips" >&2; exit 2; }
IFS=',' read -r -a T <<< "$TR"
IN=(); FC=""; OFFSET=0; PREV="0:v"; i=0
for f in "$@"; do IN+=(-i "$f"); done
for f in "$@"; do
  D=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f")
  DUR[i]=$D; i=$((i+1))
done
n=$#
for ((k=1; k<n; k++)); do
  t="${T[$(((k-1) % ${#T[@]}))]}"
  if [ "$k" -eq 1 ]; then
    OFFSET=$(awk -v d="${DUR[0]}" -v x="$XD" 'BEGIN{printf "%.3f", d-x}')
  else
    OFFSET=$(awk -v o="$OFFSET" -v d="${DUR[$((k-1))]}" -v x="$XD" 'BEGIN{printf "%.3f", o+d-x}')
  fi
  FC="${FC}[${PREV}][${k}:v]xfade=transition=${t}:duration=${XD}:offset=${OFFSET}[x${k}];"
  PREV="x${k}"
done
FC="${FC%;}"
ffmpeg -v error -y "${IN[@]}" -filter_complex "$FC" -map "[${PREV}]" -c:v libx264 -preset "${PRESET:-slow}" -crf 16 -pix_fmt yuv420p -an "$OUT"
echo "joined $n clips -> $OUT"
