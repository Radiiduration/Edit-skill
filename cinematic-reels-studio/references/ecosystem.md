# Ecosystem: other skills and repos worth borrowing from

Review any repo's SKILL.md and scripts before installing it, pin versions, and prefer releases that are at least two weeks old. Skills run with your agent's permissions.

| Repo | What it offers | Borrow |
|---|---|---|
| `remotion-dev/skills` (official) | Remotion agent skills: markup, 3D, transitions, light leaks, motion blur, effects, color correction, captions, audio visualization, maps, rendering, SaaS | Load the matching rule before writing Remotion code. Install: `npx skills add remotion-dev/skills`. *Checked by cloning the repo.* |
| `bestagentkits/motion-video-skill` | Beat-synced 1080p motion-graphic videos in HyperFrames (HTML + GSAP) with AI voice-over, karaoke captions, SFX | Its audio and beat-sync approach; an HTML/GSAP alternative to Remotion. *Read from its public description, not reviewed in depth.* |
| `kajisho5/ffmpeg-skill` | FFmpeg skill with probe, edit, verify flow and a `doctor` check, tested across ffmpeg versions | Verification discipline, version-matrix thinking. *Public description only.* |
| `agricidaniel/claude-video` | Video production suite wrapping FFmpeg, Whisper, Remotion, image/video generation, Real-ESRGAN, Demucs | Caption pipeline (Whisper), audio clean-up (Demucs / DeepFilterNet), upscaling. *Public description only.* |
| Cutboard (listed under `rakesh0x/OpenCardboard`; confirm the repo) | Chat-to-edit editor with local Whisper transcription, beat detection and 30+ typed tools | Idea: per-section cut density driven by the beat grid. *Public description only; confirm repo name before use.* |

## How this skill uses them
- Hooks, 3D, transitions, light leaks, motion blur: Remotion's official rules (`motion-3d.md`).
- Beat sync: `scripts/beatmap.py` (own implementation; librosa if present).
- Verification: `scripts/verify.sh` with automated hard-fail checks and exit codes.
- Captions: Whisper word timings into `KineticCaptions` or an ASS file.

## Ideas to add later
- Demucs stem separation to duck or accent only the drums or vocals.
- Whisper word-level timestamps wired into `KineticCaptions` automatically.
- A LUT pack (your own or licensed `.cube` files) passed to `grade.sh`.
- Depth-map 2.5D parallax for stills.
