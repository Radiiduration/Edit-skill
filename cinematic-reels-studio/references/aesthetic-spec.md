# Aesthetic Spec: what "cinematic and premium" means here

## Delivery
- 1080x1920, 9:16, 30 fps (24 for filmic feel; 60 only as source for speed ramps), H.264 High, yuv420p, AAC 48 kHz, 12 to 20 Mbps video, `-movflags +faststart`.
- Length 15 to 30 s default. Loop-friendly end (last frame rhymes with the first).
- Safe zones: keep text and key subjects clear of the top ~12% and bottom ~25%, and ~6% of each side.

## Hook (first 1.5 s)
- Strongest visual + immediate motion. No fade-in from black, no logo, no slow title.
- Text hook on screen within 0.5 s: 3 to 7 words, a curiosity or claim, large.
- Sound hit on frame 1 (impact, riser start or beat).

## Pacing (anti-slideshow)
- Nothing static > 1 s. Every shot has camera motion (push-in, slide, handheld drift, parallax) or subject motion.
- Shot length 0.5 to 2.5 s, deliberately varied: build rhythm, then one longer hold at the emotional peak.
- Cut on beat or on action. Prefer match cuts, whip pans, speed ramps, masked wipes, J/L cuts. Crossfades only as a deliberate soft moment.
- Pacing curve: fast open, build, peak at the drop, brief breath, strong finish.

## Camera and footage
- Reframe to 9:16 with intent: scale 105 to 115% for room to animate slow pushes (keep final resolution sharp; avoid soft upscaled stills).
- Stills: use 2.5D parallax (separate layers) or Ken Burns with easing, never a bare zoom.
- Speed ramps: ease in/out (e.g. 100% to 25% to 100%) timed to hits; use optical-flow `minterpolate` only on clean motion.

## Colour and image
- One coherent look across all shots; match exposure and white balance first, then stylise.
- Contrast S-curve, controlled blacks (not crushed), soft highlight roll-off, gentle saturation control, one accent colour for graphics.
- Finishing: subtle vignette, fine film grain (low opacity, animated), optional light bloom/halation on highlights. Subtle beats heavy.
- ffmpeg tools: `curves`, `eq`, `colorbalance`, `colorchannelmixer`, `lut3d` (if a LUT is available), `vignette`, `noise=alls=6:allf=t+u`, `gblur` + `blend=screen` for bloom.

## Motion graphics
- Easing: cubic-bezier or springs. Ease-out for entrances, ease-in for exits. Never linear. Overshoot minimal.
- Stagger element entrances by 2 to 4 frames. Animate masks, wipes, tracking, scale + blur reveals, not just opacity.
- Motion blur on fast moves. Depth through parallax, soft shadow, slight blur on background.
- Kinetic type: words land on beats, key word emphasised (size, colour or weight), clean exits. One or two typefaces max, strong hierarchy, tight tracking on display text, generous margins.
- Captions: large, high contrast, max 2 lines, 3 to 5 words at a time, no mid-word breaks, inside safe zones.
- Graphics never cover the subject. Every animation must inform, emphasise or transition.
- Remotion: use `spring()`, `interpolate()` with `Easing.bezier`, `<Sequence>`, `useCurrentFrame`; render alpha layers (`--codec=prores --prores-profile=4444` or VP8/VP9 with alpha) for ffmpeg compositing.

## Sound
- The edit is built on the beat map. Cuts land on beats; hits land on text.
- SFX layers: whooshes on moves, impacts on text, risers into drops, subtle ambience or room tone under everything.
- Duck music under voice. Target -14 LUFS integrated, true peak below -1 dBTP. No clipping, no silent gaps, no abrupt cuts (fade or crossfade audio at every edit).
- Use only music/SFX the user has rights to use.

## Reach
- Hook must work as a muted thumbnail at frame 0.
- Burned-in captions (many watch muted).
- Cover frame: clean, high contrast, readable title, inside the grid-crop safe area.
- Caption: first line repeats the hook; ask a question or promise a payoff; 3 to 5 relevant hashtags.
