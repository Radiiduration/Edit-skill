# Motion graphics and 3D

Remotion renders React as video, frame by frame. Everything must be a pure function of the current frame, which is what makes renders deterministic and lets 3D, type and effects stay locked to the beat map.

Starter code (type-checked against Remotion 4.0.536 strict TypeScript; **not render-tested** in the authoring sandbox, so render a 2 s test before building on it):
- `templates/remotion/tokens.ts`: colour, type, easing, spring, safe zones. One accent colour. Change tokens, not components.
- `templates/remotion/ReelKit.tsx`: `KineticCaptions`, `HookTitle`, `BeatPunch`, `FlashFrame`, `SafeZoneGuide`.
- `templates/remotion/Hero3D.tsx`: glossy 3D hero object with eased orbit + push and studio lighting.

## Setup
```bash
npx create-video@latest            # or add to an existing project
npx remotion add @remotion/three @remotion/transitions @remotion/effects @remotion/motion-blur @remotion/captions @remotion/media-utils
npx remotion versions              # confirm all @remotion/* share one version
```
Install the official agent skills for current API detail: `npx skills add remotion-dev/skills`. Rules worth loading on demand: `3d`, `transitions`, `light-leaks`, `motion-blur`, `effects`, `color-correction`, `captions`, `audio-visualization`, `text-highlights`, `sfx`, `ffmpeg`, `calculate-metadata`. Version gates noted in those rules: `lightLeak()` needs Remotion 4.0.500+; `<HtmlInCanvasMotionBlur>` needs 4.0.529+ (live preview additionally needs Chrome 149+ with the HTML-in-canvas flag; renders need no config).

## 3D rules (from Remotion's own 3D guidance)
1. Wrap all 3D in `<ThreeCanvas width={width} height={height}>` from `@remotion/three`, sized from `useVideoConfig()`.
2. Always add lights. A scene without lights renders black.
3. Animate only from `useCurrentFrame()`. Never use `useFrame()` from react-three-fiber and never rely on self-running shaders or models: they flicker in renders.
4. Use `@react-three/fiber` v8 with React 18 (v9 needs React 19). Match the `three` and `@types/three` versions.

## Making 3D look expensive
- Dark, controlled background (`COLOR.ink`), not a flat grey default.
- Three-point light: bright key from one side, **accent-coloured rim** from behind, low ambient fill. Add a faint accent point light below for a glow.
- Glossy materials: `meshPhysicalMaterial` with `metalness` 0.8 to 0.9, `roughness` 0.15 to 0.3, `clearcoat` 1.
- Camera: narrow field of view (28 to 40) like a real lens, never wider. Eased orbit plus push-in (`EASE.inOut` / `EASE.out`), never linear.
- Depth cues: fog, a second softer object out of focus (blur layer behind), parallax between layers.
- Scale pulses on beats (`BeatPunch`) and a flash or chromatic burst on the drop.
- What to put in 3D: a hero object or logo, extruded title text, floating UI cards, product turntables, camera flythroughs, map flyovers (Remotion maps rules: Cesium for 3D terrain, Mapbox/MapLibre for flat).
- Photoreal needs: Blender headless (`blender -b scene.blend -o //f_#### -F PNG -a`) then assemble with ffmpeg. Slower, but a different quality tier.
- Stills to depth: separate subject/background layers (or a depth map from a model such as Depth Anything) and move layers at different speeds for 2.5D parallax. Do not use a bare zoom on a flat still.

## Composition pattern for a Reel
```
<AbsoluteFill>
  <BeatPunch beats={beats}>          // pulse the whole frame on beats
    <Video .../>                      // or <Hero3D/> as the base layer
  </BeatPunch>
  <TransitionSeries> ... </TransitionSeries>   // real transitions + light-leak overlays
  <HookTitle lines={['NOBODY SHOWS', 'THIS SIDE']} />
  <KineticCaptions words={words} />
  <FlashFrame atFrames={dropFrames} />
</AbsoluteFill>
```
Load `beats` from `.studio/beatmap.json` (seconds) with `staticFile` or inline it; convert to frames with `Math.round(t * fps)`.

## Transitions and light leaks
`<TransitionSeries>` with `<TransitionSeries.Transition presentation={slide()} timing={springTiming(...)}>` shortens the timeline (both scenes overlap). `<TransitionSeries.Overlay>` plays an effect over the cut point without shortening it: put `lightLeak()` there. Vary presentations (slide, wipe, flip, clock-wipe) and match them to camera motion; never rely on `fade()` alone.

## Motion blur
Fast moves need motion blur or they strobe. Use `<HtmlInCanvasMotionBlur shutterAngle={180} samples={8}>` for animated HTML/type, `@remotion/motion-blur` for the rest (see its rule). Raise `samples` only if banding shows; cost grows linearly.

## Typography motion
Mask or clip reveals, scale + blur-to-sharp, per-line stagger of 2 to 4 frames, key word in the accent colour, clean exit (ease-in, 6 to 8 frames). Land words on beats. Highlights and hand-drawn circles: `@remotion/rough-notation` (`text-highlights` rule). Captions: `@remotion/captions` with word timings; max 2 lines, 3 to 5 words, inside `SAFE`.

## Audio-reactive
`useWindowedAudioData` + `visualizeAudio` (`@remotion/media-utils`) gives bass energy per frame for pulsing glows or bars. Prefer beat-map pulses (`BeatPunch`) for cuts and impacts, audio-reactive for ambient motion.

## Render alpha layers for ffmpeg compositing
Confirm the exact flags with `npx remotion render --help` for your version, then for example:
```bash
npx remotion render src/index.ts TitleLayer out/title.mov --codec=prores --prores-profile=4444 --image-format=png --pixel-format=yuva444p10le
npx remotion render src/index.ts TitleLayer out/title.webm --codec=vp9 --image-format=png --pixel-format=yuva420p
```
Composite (tested): 
```bash
ffmpeg -i base.mp4 -i out/title.mov -filter_complex "[0:v][1:v]overlay=format=auto,format=yuv420p" -c:v libx264 -preset slow -crf 16 comp.mp4
```
Then grade the **composite** with `scripts/grade.sh` so graphics and footage share one look, grain included.

## Performance
3D and blur render slowly. Preview at low resolution (`--scale=0.5`), render finals at full size, tune `--concurrency`, and render test stills of the hook (`npx remotion still`) before full renders. Check Remotion's render docs for GPU flags (`--gl`) if WebGL is slow or fails.
