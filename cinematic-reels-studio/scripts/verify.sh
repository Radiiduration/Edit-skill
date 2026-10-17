#!/usr/bin/env bash
# Usage: verify.sh <video.mp4> <outdir>
# Evidence + automated hard-fail checks for the QC Reviewer.
# Exit code 0 = no automated FAIL, 1 = at least one FAIL. WARN never fails.
set -u
IN="${1:?video path}"; OUT="${2:?output dir}"
mkdir -p "$OUT/frames"
R="$OUT/report.txt"; : > "$R"
FAILS=0
say()  { echo "$@" | tee -a "$R"; }
pass() { say "PASS  $1"; }
warn() { say "WARN  $1"; }
fail() { say "FAIL  $1"; FAILS=$((FAILS+1)); }

say "== ffprobe =="
ffprobe -v error -show_entries format=duration,size,bit_rate:stream=codec_name,width,height,r_frame_rate,pix_fmt,sample_rate,channels \
  -of default=nw=1 "$IN" | tee -a "$R"

W=$(ffprobe -v error -select_streams v:0 -show_entries stream=width  -of csv=p=0 "$IN")
H=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$IN")
FPS=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$IN")
VC=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$IN")
PF=$(ffprobe -v error -select_streams v:0 -show_entries stream=pix_fmt -of csv=p=0 "$IN")
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$IN")
HAS_AUDIO=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$IN")

say "== automated checks =="
[ "$W" = "1080" ] && [ "$H" = "1920" ] && pass "resolution 1080x1920" || fail "resolution ${W}x${H} (want 1080x1920)"
case "$FPS" in 24/1|30/1|60/1|30000/1001|24000/1001) pass "fps $FPS";; *) fail "fps $FPS (want 24/30/60)";; esac
[ "$VC" = "h264" ] && pass "codec h264" || fail "codec $VC (want h264)"
[ "$PF" = "yuv420p" ] && pass "pix_fmt yuv420p" || fail "pix_fmt $PF (want yuv420p for Instagram)"
awk -v d="$DUR" 'BEGIN{exit !(d>=5 && d<=90)}' && pass "duration ${DUR}s" || warn "duration ${DUR}s outside 5-90 s"
awk -v d="$DUR" 'BEGIN{exit !(d>=7 && d<=35)}' || warn "duration ${DUR}s outside the 7-35 s sweet spot"

ffmpeg -v error -y -i "$IN" -vf "fps=2,scale=540:-1" "$OUT/frames/f_%04d.jpg"
ffmpeg -v error -y -i "$IN" -frames:v 1 "$OUT/first.jpg"
ffmpeg -v error -y -sseof -0.1 -i "$IN" -frames:v 1 -update 1 "$OUT/last.jpg"
ffmpeg -v error -y -i "$IN" -vf "fps=2,scale=216:-1,tile=8x6" -frames:v 1 "$OUT/contact.jpg"
# Safe-zone overlay on the first frame: red = platform UI zones (top 12%, bottom 25%, sides 6%).
ffmpeg -v error -y -i "$OUT/first.jpg" -vf "drawbox=x=0:y=0:w=iw:h=ih*0.12:color=red@0.35:t=fill,drawbox=x=0:y=ih*0.75:w=iw:h=ih*0.25:color=red@0.35:t=fill,drawbox=x=0:y=0:w=iw*0.06:h=ih:color=red@0.25:t=fill,drawbox=x=iw*0.94:y=0:w=iw*0.06:h=ih:color=red@0.25:t=fill" "$OUT/first_safezones.jpg"

say "== scene cuts (seconds) =="
CUTS=$(ffmpeg -v info -i "$IN" -vf "select='gt(scene,0.3)',showinfo" -an -f null - 2>&1 | grep -o "pts_time:[0-9.]*" | cut -d: -f2)
echo "$CUTS" | tee -a "$R"
NC=$(echo "$CUTS" | grep -c . || true)
awk -v n="$NC" -v d="$DUR" 'BEGIN{ if (n>0) printf "avg shot length ~ %.2f s over %d detected cuts\n", d/(n+1), n }' | tee -a "$R"

say "== black frames =="
BL=$(ffmpeg -v info -i "$IN" -vf "blackdetect=d=0.05:pix_th=0.10" -an -f null - 2>&1 | grep blackdetect || true)
if [ -n "$BL" ]; then echo "$BL" | tee -a "$R"; fail "black frames detected (a deliberate fade must be justified in the shot list)"; else pass "no black frames"; fi

say "== freeze frames =="
FR=$(ffmpeg -v info -i "$IN" -vf "freezedetect=n=-60dB:d=0.7" -an -f null - 2>&1 | grep freeze_start || true)
if [ -n "$FR" ]; then echo "$FR" | tee -a "$R"; fail "frozen/static segment over 0.7 s"; else pass "no frozen segments"; fi

say "== loudness (target about -14 LUFS, true peak below -1 dBTP) =="
if [ -z "$HAS_AUDIO" ]; then
  warn "no audio stream"
else
  EB=$(ffmpeg -v info -i "$IN" -af "ebur128=peak=true" -vn -f null - 2>&1 | tail -n 14)
  echo "$EB" | tee -a "$R"
  LUFS=$(echo "$EB" | awk '/^ *I:/{print $2}' | tail -1)
  TP=$(echo "$EB" | awk '/Peak:/{print $2}' | tail -1)
  if [ -n "$LUFS" ]; then
    awk -v l="$LUFS" 'BEGIN{exit !(l>=-16 && l<=-12)}' && pass "integrated ${LUFS} LUFS" || fail "integrated ${LUFS} LUFS (want -16..-12)"
  fi
  if [ -n "$TP" ]; then
    awk -v p="$TP" 'BEGIN{exit !(p<=-1)}' && pass "true peak ${TP} dBTP" || fail "true peak ${TP} dBTP (want <= -1)"
  fi
fi

say "== summary =="
if [ "$FAILS" -eq 0 ]; then say "RESULT: no automated failures. Visual QC from frames is still required."; else say "RESULT: $FAILS automated FAIL(s)."; fi
say "Evidence in $OUT (first.jpg, first_safezones.jpg, last.jpg, contact.jpg, frames/)"
[ "$FAILS" -eq 0 ]
