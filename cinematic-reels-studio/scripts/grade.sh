#!/usr/bin/env bash
# Usage: grade.sh <in.mp4> <out.mp4> <look> [lut.cube]
# Looks: teal-orange | moody-night | warm-film | clean-crisp | bleach-lite
# Applies one coherent grade + finishing (bloom/halation, vignette, animated grain). Audio copied.
# If a .cube LUT is given it is applied first (then the look's finishing).
set -eu
IN="${1:?input}"; OUT="${2:?output}"; LOOK="${3:?look}"; LUT="${4:-}"
GRAIN="noise=alls=6:allf=t+u"
VIG="vignette=angle=PI/5"
case "$LOOK" in
  teal-orange) BASE="curves=all='0/0.02 0.25/0.21 0.5/0.52 0.75/0.8 1/0.98',colorbalance=rs=-0.06:gs=0.0:bs=0.09:rh=0.08:gh=0.02:bh=-0.07,eq=saturation=1.1:contrast=1.04"; BLOOM=0.25 ;;
  moody-night) BASE="curves=all='0/0.0 0.3/0.24 0.6/0.58 1/0.95',colorbalance=rs=-0.04:bs=0.1:rm=-0.02:bm=0.05:rh=0.04,eq=saturation=1.05:contrast=1.08:brightness=-0.02"; BLOOM=0.35 ;;
  warm-film)   BASE="curves=all='0/0.04 0.5/0.5 1/0.96',colorbalance=rs=0.03:rm=0.04:rh=0.05:bh=-0.04,eq=saturation=1.02:contrast=1.02"; BLOOM=0.3; GRAIN="noise=alls=9:allf=t+u" ;;
  clean-crisp) BASE="curves=all='0/0 0.25/0.22 0.75/0.8 1/1',eq=saturation=1.06:contrast=1.03"; BLOOM=0.12; GRAIN="noise=alls=3:allf=t+u" ;;
  bleach-lite) BASE="curves=all='0/0 0.3/0.25 0.7/0.76 1/1',eq=saturation=0.8:contrast=1.15"; BLOOM=0.15 ;;
  *) echo "unknown look '$LOOK' (teal-orange|moody-night|warm-film|clean-crisp|bleach-lite)" >&2; exit 2 ;;
esac
PRE=""
if [ -n "$LUT" ]; then PRE="lut3d=file='${LUT}',"; fi
# Bloom/halation: isolate highlights, blur, warm-tint, screen back on top.
FC="[0:v]${PRE}${BASE},split[a][b];[b]curves=all='0/0 0.62/0 1/1',scale=iw/4:ih/4,gblur=sigma=7,scale=iw*4:ih*4:flags=bicubic,colorchannelmixer=rr=1:gg=0.62:bb=0.42[hl];[a][hl]blend=all_mode=screen:all_opacity=${BLOOM},${VIG},${GRAIN},format=yuv420p[v]"
ffmpeg -v error -y -i "$IN" -filter_complex "$FC" -map "[v]" -map "0:a?" -c:v libx264 -preset "${PRESET:-slow}" -crf 16 -c:a copy -movflags +faststart "$OUT"
echo "graded ($LOOK): $OUT"
