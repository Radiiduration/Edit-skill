#!/usr/bin/env bash
# Usage: doctor.sh
# Toolchain check. Prints what exists so the Orchestrator never assumes a tool.
set -u
ok()   { printf '  [ok]      %s\n' "$1"; }
miss() { printf '  [missing] %s\n' "$1"; }

echo "== core =="
for t in ffmpeg ffprobe; do
  if command -v "$t" >/dev/null 2>&1; then ok "$t $("$t" -version 2>/dev/null | head -1 | awk '{print $3}')"; else miss "$t (required)"; fi
done

if command -v ffmpeg >/dev/null 2>&1; then
  echo "== ffmpeg filters the recipes use =="
  filters="$(ffmpeg -hide_banner -filters 2>/dev/null)"
  for f in xfade zoompan minterpolate loudnorm sidechaincompress acrossfade rgbashift lut3d blend gblur vignette noise curves colorbalance ebur128 freezedetect blackdetect drawbox; do
    if printf '%s' "$filters" | grep -qE " $f "; then ok "$f"; else miss "$f"; fi
  done
  for f in subtitles drawtext; do
    if printf '%s' "$filters" | grep -qE " $f "; then ok "$f (text burn-in)"; else miss "$f (needs libass / libfreetype build)"; fi
  done
  if ffmpeg -hide_banner -encoders 2>/dev/null | grep -q libx264; then ok "libx264"; else miss "libx264"; fi
  if ffmpeg -hide_banner -encoders 2>/dev/null | grep -qE "prores_ks"; then ok "prores_ks (alpha layers)"; else miss "prores_ks"; fi
fi

echo "== motion graphics =="
if command -v node >/dev/null 2>&1; then ok "node $(node -v)"; else miss "node (needed for Remotion)"; fi
if [ -f package.json ] && grep -q '"remotion"' package.json; then
  ok "remotion in package.json"
  for p in @remotion/three @remotion/transitions @remotion/effects @remotion/motion-blur @remotion/captions @remotion/media-utils; do
    if grep -q "\"$p\"" package.json; then ok "$p"; else miss "$p (npx remotion add ${p})"; fi
  done
else
  miss "remotion project in current dir (cd into the project, or create one)"
fi

echo "== audio analysis / captions =="
if command -v python3 >/dev/null 2>&1; then
  ok "python3"
  python3 -c "import numpy" 2>/dev/null && ok "numpy (beatmap.py fallback)" || miss "numpy (pip install numpy)"
  python3 -c "import librosa" 2>/dev/null && ok "librosa (best beat tracking)" || miss "librosa (optional: pip install librosa)"
else
  miss "python3"
fi
if command -v whisper >/dev/null 2>&1 || command -v whisper-cli >/dev/null 2>&1 || python3 -c "import whisper" 2>/dev/null; then ok "whisper (word-level captions)"; else miss "whisper (optional, for captions)"; fi
