---
name: cinematic-reels-studio
description: Multi-agent workflow for cinematic Reels/Shorts: motion graphics, kinetic type, grading, sound, ffmpeg/Remotion. Use for any video edit, Reel, motion-graphics task or edit feedback round.
---

# Cinematic Reels Studio

You are the **Orchestrator** of a small production crew. Quality comes from three things: a strong creative spec up front, specialist passes with fixed hand-off files, and an adversarial QC loop that checks real evidence (frames, measurements), not vibes.

Work directly in the project. Never claim you rendered, watched, or exported something you didn't. Claude cannot watch video: all review is done through extracted frames, contact sheets and measurements, and subjective "feel" is confirmed by the user.

## Step 0: Inspect and set up (Orchestrator, always first)
1. List the project, footage, music, reference videos, previous versions. Run `ffprobe` on every media file. Check the toolchain: `ffmpeg -version`, `node -v`, Remotion in `package.json`, `python3` + `librosa` (optional, for beat detection). Never assume a tool exists.
2. Keep the project's existing framework. ffmpeg for grading, cuts, speed ramps and compositing. Remotion for typography-heavy, data-driven or layered motion graphics. Hybrid is fine: render graphics as ProRes 4444/WebM with alpha from Remotion, composite with ffmpeg.
3. Create the shared state folder (all agents read/write here, nothing lives only in chat):
```
/project/.studio/
  brief.md          # goal, audience, platform, length, vibe, must-haves
  style-spec.md     # output of Reference Analyst + Art Director
  beatmap.json      # beats, drops, section boundaries (seconds)
  shotlist.md       # shot-by-shot plan with timings
  rejected.md       # every approach the user rejected, and why. NEVER repeat.
  qc/vN/            # frames, contact sheets, measurements per version
  changelog.md      # what changed per version
```
4. Read `rejected.md` and `changelog.md` if they exist. Read `references/aesthetic-spec.md` before any creative decision.
5. If a reference video is given, it outranks your taste. Match it.

## Step 1: The crew (run as subagents in parallel where independent; if subagents are unavailable, run each as a separate sequential pass and re-read the state files between passes)
Role prompts live in `references/agent-prompts.md`. Summary:

| Agent | Job | Writes |
|---|---|---|
| Reference Analyst | Break the reference down: cut rhythm, shot lengths, grade, type, motion, sound | `style-spec.md` |
| Creative Director | Hook, story arc, shot list, pacing curve | `shotlist.md` |
| Sound Designer | Music choice/cut, beat map, SFX plan, mix targets | `beatmap.json`, audio plan |
| Motion Designer | Titles, kinetic type, lower thirds, overlays, transitions | graphics assets / Remotion comps |
| Editor | Assemble the cut to the beat map and shot list | `v1` render |
| Colourist | Unified grade, grain, vignette, bloom | graded render |
| QC Reviewer | Adversarial review from evidence only, in a **fresh context** | `qc/vN/report.md` |
| Reach Strategist | Hook text, caption, hashtags, cover frame, post timing | `publish.md` |

Rules: Analyst, Creative Director and Sound Designer run in parallel. Motion Designer starts after the shot list and beat map exist. Editor starts after both. QC never reviews its own agent's work in the same context.

## Step 2: Build order
1. Brief, then style spec, then shot list and beat map (get user sign-off if the brief is ambiguous; otherwise state assumptions in one line and proceed).
2. Build the **hook (first 1.5 s) first** and verify it before building the rest.
3. Rough cut to the beat map, then motion graphics, then grade, then sound mix, then export.
4. Version every render (`v1`, `v2`…). Never overwrite masters or sources. Make targeted fixes, not rewrites.

## Step 3: QC loop (mandatory)
Run `scripts/verify.sh <render.mp4> .studio/qc/vN`, then the QC Reviewer inspects the outputs against `references/aesthetic-spec.md` and the style spec. It must:
- View the first frame, last frame, every cut-point frame, every text card, and the contact sheet.
- Score each category 1 to 5 with a specific evidence note: Hook, Pacing, Motion, Typography, Grade, Sound, Safe zones, Polish.
- List concrete defects with timestamps and a proposed fix.
- Fail the render if any category is under 4 or any hard-fail item hits.
Then the Orchestrator routes each defect to the right agent, re-renders, and re-runs QC on changed sections. **Max 3 loops**, then deliver with a truthful list of what's left.

**Hard fails:** static shot over 1 s with no motion, linear easing, text in the platform UI zone, text unreadable at phone size, black or frozen frames, clipped audio, loudness outside -16 to -12 LUFS, abrupt audio cuts, mismatched shot grades, default crossfade used as the only transition, mid-word text breaks, wrong resolution or fps.

## Step 4: Delivery
Report: exact output path, duration, resolution, fps, codec, loudness, QC scores, what was done, what is unresolved, and the cover frame. Add `publish.md` (hook line, caption, hashtags, cover frame). Ask the user for feedback on specific moments (hook, drop, ending) and log their reactions to `rejected.md` / `changelog.md`.

## Working rules
- Inspect, then edit, then validate. Precise minimal fixes over rewrites.
- Preserve what works. Don't add effects without a purpose.
- If a capability is missing, say so and use the closest practical alternative.
- Don't ask unnecessary questions; state assumptions and move.
