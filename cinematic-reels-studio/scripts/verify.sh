#!/usr/bin/env bash
# Usage: verify.sh <video.mp4> <outdir>
# Evidence for the QC Reviewer: stream info, frames, contact sheet,
# scene cuts, black/freeze detection, loudness.
set -u
IN="${1:?video path}"; OUT="${2:?output dir}"
mkdir -p "$OUT/frames"
R="$OUT/report.txt"; : > "$R"

echo "== ffprobe ==" | tee -a "$R"
ffprobe -v error -show_entries format=duration,size,bit_rate:stream=codec_name,width,height,r_frame_rate,pix_fmt,sample_rate,channels \
  -of default=nw=1 "$IN" | tee -a "$R"

ffmpeg -v error -y -i "$IN" -vf "fps=2,scale=540:-1" "$OUT/frames/f_%04d.jpg"
ffmpeg -v error -y -i "$IN" -frames:v 1 "$OUT/first.jpg"
ffmpeg -v error -y -sseof -0.1 -i "$IN" -frames:v 1 -update 1 "$OUT/last.jpg"
ffmpeg -v error -y -i "$IN" -vf "fps=2,scale=216:-1,tile=8x6" -frames:v 1 "$OUT/contact.jpg"

echo "== scene cuts (seconds) ==" | tee -a "$R"
ffmpeg -v info -i "$IN" -vf "select='gt(scene,0.3)',showinfo" -an -f null - 2>&1 \
  | grep -o "pts_time:[0-9.]*" | tee -a "$R"

echo "== black frames ==" | tee -a "$R"
ffmpeg -v info -i "$IN" -vf "blackdetect=d=0.05:pix_th=0.10" -an -f null - 2>&1 | grep blackdetect | tee -a "$R"

echo "== freeze frames ==" | tee -a "$R"
ffmpeg -v info -i "$IN" -vf "freezedetect=n=-60dB:d=0.5" -an -f null - 2>&1 | grep freeze | tee -a "$R"

echo "== loudness (target ~-14 LUFS, true peak < -1 dBTP) ==" | tee -a "$R"
ffmpeg -v info -i "$IN" -af "ebur128=peak=true" -vn -f null - 2>&1 | tail -n 14 | tee -a "$R"

echo "Done. Evidence in $OUT"
