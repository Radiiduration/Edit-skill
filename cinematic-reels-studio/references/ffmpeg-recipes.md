# ffmpeg recipes (every recipe below was run on ffmpeg 6.1)

Use 1080x1920, 30 fps unless the style spec says otherwise. Add `-c:v libx264 -preset slow -crf 16 -pix_fmt yuv420p -movflags +faststart` for finals. Run `scripts/doctor.sh` to confirm a filter exists before using it.

## Reframe 16:9 to 9:16 with a blurred fill (no black bars)
```bash
ffmpeg -i in.mp4 -filter_complex "[0:v]split[a][b];[a]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,gblur=sigma=40,eq=brightness=-0.08[bg];[b]scale=1080:-2[fg];[bg][fg]overlay=(W-w)/2:(H-h)/2,format=yuv420p" out.mp4
```
Better when the subject allows it: crop to 9:16 around the subject (`crop=ih*9/16:ih:x:0,scale=1080:1920`) and animate `x` for a reframe move.

## Beat punch (scale pulse that decays after each beat)
Replace `0.5` with the beat period from `beatmap.json` (60 / bpm).
```bash
ffmpeg -i in.mp4 -vf "scale=w='trunc(1080*(1+0.06*exp(-12*mod(t,0.5)))/2)*2':h=-2:eval=frame,crop=1080:1920,format=yuv420p" out.mp4
```
For a drifting beat grid, render the pulse in Remotion with `BeatPunch` (templates) using the real beat times.

## Eased Ken Burns on a still (ease-out cubic push-in)
Upscale first to avoid zoompan jitter. `59` is `d - 1`.
```bash
ffmpeg -loop 1 -t 2 -i still.png -vf "scale=3200:-2,zoompan=z='1+0.18*(1-pow(1-on/59,3))':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=60:s=1080x1920:fps=30,format=yuv420p" -an out.mp4
```
For depth, prefer 2.5D parallax: cut the subject from the background into layers, move each at a different speed in Remotion.

## Handheld drift (crop window wanders on layered sines)
```bash
ffmpeg -i in.mp4 -vf "scale=1166:2074,crop=1080:1920:x='43+14*sin(t*7.3)+6*sin(t*17.1)':y='77+14*sin(t*5.9+1)+6*sin(t*13.7)',format=yuv420p" out.mp4
```
Keep amplitude under 1.5% of frame size. More looks like an accident, not a camera.

## Impact accents (timed with `enable`)
```bash
# chromatic aberration burst, 0.2 s
-vf "rgbashift=rh=-6:bh=6:enable='between(t,0.5,0.7)'"
# white flash on a hit, 0.1 s
-vf "drawbox=x=0:y=0:w=iw:h=ih:color=white@0.85:t=fill:enable='between(t,0.5,0.6)'"
```

## Light leak / glow overlay on a cut
With a light-leak clip (footage you have rights to) as input 1:
```bash
ffmpeg -i main.mp4 -i leak.mp4 -filter_complex "[0:v][1:v]blend=all_mode=screen:all_opacity=0.55,format=yuv420p" out.mp4
```
In Remotion use `lightLeak()` from `@remotion/effects` inside `<TransitionSeries.Overlay>` (see `motion-3d.md`).

## Transitions that are not a crossfade
`scripts/xfade_chain.sh out.mp4 0.4 slideleft,smoothleft,zoomin,circleopen,fadewhite clip1 clip2 ...`
Match transition to motion: whip/slide for camera moves, `zoomin` for push-ins, `fadewhite` or a flash for a hit, `circleopen` or `radial` for reveals. Keep them 0.25 to 0.5 s. Every join shortens the timeline by the xfade duration, so plan cut times after that.

## Eased speed ramp
`scripts/speed_ramp.sh in.mp4 out.mp4 1.2 2.0 0.3 10` ramps 1x to 0.3x to 1x between 1.2 s and 2.0 s. Shoot 60 fps for clean slow-mo, or add `minterpolate=fps=60:mi_mode=mci` only on clean, low-noise motion (it smears fast detail).

## Grade and finishing
`scripts/grade.sh in.mp4 out.mp4 teal-orange` (also `moody-night`, `warm-film`, `clean-crisp`, `bleach-lite`; optional `.cube` LUT as 4th argument). Chain: curves S-curve, colour balance, bloom/halation from highlights, vignette, animated grain. Subtle beats heavy. Match exposure and white balance per shot before applying a look.

## Burned-in animated captions (ASS)
Generate an `.ass` file from word timings (Whisper `--word_timestamps` or the user's script), style it, then:
```bash
ffmpeg -i in.mp4 -vf "subtitles=captions.ass,format=yuv420p" -c:a copy out.mp4
```
ASS pop-in on a word: `{\fad(80,60)\t(0,120,\fscx115\fscy115)\t(120,240,\fscx100\fscy100)}WORD`. Use `PlayResX: 1080`, `PlayResY: 1920`, bottom margin ~480 (inside the safe area), max 2 lines. For richer kinetic type use `KineticCaptions` in Remotion.

## Audio: SFX on beats and ducking under voice
```bash
# SFX layered at 1.0 s (repeat per hit, offset in ms)
ffmpeg -i music.wav -i hit.wav -filter_complex "[1:a]adelay=1000|1000,volume=1.5[s];[0:a][s]amix=inputs=2:duration=first:normalize=0[a]" -map "[a]" mix.m4a
# duck music (0) under voice (1)
ffmpeg -i music.wav -i voice.wav -filter_complex "[1:a]volume=0.5,asplit=2[v1][v2];[0:a][v1]sidechaincompress=threshold=0.03:ratio=8:attack=20:release=300[duck];[duck][v2]amix=inputs=2:normalize=0[a]" -map "[a]" mix.m4a
```
Then `scripts/loudnorm.sh mix_video.mp4 final.mp4 -14 -1.5`. Fade or crossfade audio at every edit; never leave a silent gap.

## Delivery encode
```bash
ffmpeg -i graded.mp4 -c:v libx264 -preset slow -crf 16 -pix_fmt yuv420p -r 30 -c:a aac -b:a 256k -ar 48000 -movflags +faststart final.mp4
```
Then `scripts/verify.sh final.mp4 .studio/qc/vN`.
