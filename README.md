# Edit-skill

![validate](https://github.com/Radiiduration/Edit-skill/actions/workflows/validate.yml/badge.svg)

Claude skills for premium short-form video. Currently: **cinematic-reels-studio**, a multi-agent workflow for cinematic Reels/Shorts with hook-first editing, beat-synced cuts, motion + 3D graphics (Remotion, `@remotion/three`), grading, sound design, and an evidence-based QC loop (ffmpeg).

## What is inside
```
cinematic-reels-studio/
  SKILL.md                    # the workflow (Orchestrator + crew + QC loop)
  references/                 # aesthetic spec, hook playbook, ffmpeg recipes, motion + 3D, ecosystem, agent prompts
  scripts/                    # doctor, beatmap, xfade_chain, speed_ramp, grade, loudnorm, verify
  templates/remotion/         # tokens, kinetic captions, hook title, beat punch, 3D hero shot
tests/smoke.sh                # runs every script on generated clips (also runs in CI)
```

## Install (Claude Code)
```bash
git clone https://github.com/Radiiduration/Edit-skill.git ~/code/Edit-skill
ln -s ~/code/Edit-skill/cinematic-reels-studio ~/.claude/skills/cinematic-reels-studio
```

## Install (claude.ai)
Download `cinematic-reels-studio.zip` from the latest Release, then upload it in Settings, Capabilities, Skills.

## Requirements
- ffmpeg and ffprobe (6.x or newer recommended), python3 with numpy
- Optional: Node 18+ and a Remotion project for motion/3D, librosa for beat tracking, Whisper for captions
- Run `cinematic-reels-studio/scripts/doctor.sh` to see what is available

## Release
```bash
git tag v1.0.0 && git push origin v1.0.0   # release.yml zips the skill and attaches it to the release
```

## Notes
- Claude cannot watch video or hear audio. The skill works from extracted frames, measurements and the beat map, and asks you to confirm motion feel and music taste.
- `templates/remotion/` is type-checked against Remotion 4.0.536 but render-test it in your project before relying on it.
- Use only music, SFX, fonts and footage you have rights to use.
