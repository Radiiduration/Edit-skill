# Hook playbook (first 1.5 seconds)

The hook decides whether the rest exists. Build it first, verify it with frames, and never build the rest on a failed hook.

## Non-negotiables
- Frame 0 is already a strong image. No fade-in from black, no logo, no slow title, no "hey guys".
- Motion on frame 1: camera move, subject move or a hard-cut sequence. A static opening frame is a fail.
- Text on screen within 0.5 s, 3 to 7 words, large, inside the safe area, readable muted.
- A sound event on frame 1 (impact, riser start, beat, vocal hit).
- It must work as a muted still thumbnail: one clear subject, high contrast, one readable line.

## Hook formulas (pick one, write 3 variants)
| Formula | Pattern | Visual |
|---|---|---|
| Curiosity gap | "Nobody shows you this side of X" | Best shot first, then cut away to a wider reveal |
| Bold claim | "This is the best X in Y" | Hero shot, hard push-in, claim lands on the first beat |
| Pattern interrupt | Unexpected cut, glitch or speed ramp on frame 1 | Whip pan or flash frame into the hero shot |
| Contrast | "Day vs night", "before vs after" | Split or masked wipe between two looks in the first second |
| Payoff-first | Show the best moment, then rewind: "Here's how" | Final shot at 0 s, speed-ramp rewind transition |
| Question | "Ever seen X at golden hour?" | Strong image, question types in word by word |

## Hook construction checklist
1. Choose the single strongest shot in the footage for frame 0 (sharpest, most contrast, clear subject, motion).
2. Add camera motion in the first 12 frames (push-in 105 to 115%, whip, slide).
3. Text: kinetic entrance (mask reveal + blur-to-sharp, 12 frames, ease-out), key word in the accent colour.
4. Sound: impact or riser hit on frame 1, then lock the first cut to the first beat or downbeat.
5. First cut by 0.8 to 1.2 s. Keep shots under 1.5 s until the first peak.
6. Loop-friendly: the last frame should rhyme with the first (same subject, colour or motion direction).

## Hook QC (from extracted frames at 0, 0.5, 1.0, 1.5 s)
- Frame 0 passes the muted thumbnail test.
- Text visible at 0.5 s and not in a UI zone (see `first_safezones.jpg` from `verify.sh`).
- Visible change between each of the four frames (motion, cut or text).
- The claim or question is understandable without sound.

Score the hook 1 to 5. Under 4 means rebuild it before anything else.

## Retention structure after the hook
- 0 to 1.5 s hook, 1.5 to 8 s build (fast cuts, rising energy), peak at the drop (hold a hero shot slightly longer), a short breath, then a strong finish with a visual rhyme to the opening.
- Add a new visual event every 2 to 3 s: a new shot type, graphic, speed ramp or colour accent. Variety resets attention.
- No invented performance claims. Retention and reach depend on the content, the account and the algorithm; this playbook improves craft, not guarantees.
