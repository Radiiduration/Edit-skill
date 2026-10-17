// Reel building blocks. Everything is driven by useCurrentFrame() so renders are deterministic.
import React from 'react';
import {AbsoluteFill, interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {COLOR, EASE, SAFE, SPRING, STAGGER_FRAMES, TYPE} from './tokens';

export type CaptionWord = {text: string; start: number; end: number; emphasis?: boolean};

/** Word-by-word captions (seconds). Shows `groupSize` words at a time, each springing in on its start. */
export const KineticCaptions: React.FC<{words: CaptionWord[]; groupSize?: number}> = ({words, groupSize = 3}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = frame / fps;

  const groups: CaptionWord[][] = [];
  for (let i = 0; i < words.length; i += groupSize) groups.push(words.slice(i, i + groupSize));
  const active = groups.find((g) => t >= g[0].start && t < g[g.length - 1].end + 0.15);
  if (!active) return null;

  return (
    <AbsoluteFill
      style={{
        justifyContent: 'flex-end',
        alignItems: 'center',
        paddingBottom: SAFE.bottom + 40,
        paddingLeft: SAFE.side,
        paddingRight: SAFE.side,
      }}
    >
      <div style={{display: 'flex', flexWrap: 'wrap', justifyContent: 'center', gap: '0 24px', maxWidth: '100%'}}>
        {active.map((w, i) => {
          const local = frame - Math.round(w.start * fps);
          const p = spring({frame: local, fps, config: w.emphasis ? SPRING.pop : SPRING.snappy});
          return (
            <span
              key={`${w.start}-${i}`}
              style={{
                display: 'inline-block',
                fontFamily: TYPE.display,
                fontWeight: TYPE.weight.display,
                fontSize: w.emphasis ? TYPE.size.caption * 1.15 : TYPE.size.caption,
                letterSpacing: TYPE.tracking.display,
                textTransform: 'uppercase',
                color: w.emphasis ? COLOR.accent : COLOR.paper,
                opacity: interpolate(local, [0, 3], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'}),
                transform: `translateY(${(1 - p) * 40}px) scale(${0.85 + 0.15 * p})`,
                textShadow: '0 4px 24px rgba(0,0,0,0.55)',
              }}
            >
              {w.text}
            </span>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};

/** Hook title: mask reveal + blur-to-sharp, per-line stagger. Place inside the safe area. */
export const HookTitle: React.FC<{lines: string[]; startFrame?: number}> = ({lines, startFrame = 0}) => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill style={{justifyContent: 'center', padding: `${SAFE.top}px ${SAFE.side}px`}}>
      {lines.map((line, i) => {
        const f = frame - startFrame - i * STAGGER_FRAMES;
        const p = interpolate(f, [0, 12], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: EASE.out});
        return (
          <div key={i} style={{overflow: 'hidden', clipPath: `inset(0 ${(1 - p) * 100}% 0 0)`}}>
            <div
              style={{
                fontFamily: TYPE.display,
                fontWeight: TYPE.weight.display,
                fontSize: TYPE.size.hook,
                lineHeight: 0.95,
                letterSpacing: TYPE.tracking.display,
                textTransform: 'uppercase',
                color: i === lines.length - 1 ? COLOR.accent : COLOR.paper,
                filter: `blur(${(1 - p) * 18}px)`,
                transform: `translateY(${(1 - p) * 60}px)`,
              }}
            >
              {line}
            </div>
          </div>
        );
      })}
    </AbsoluteFill>
  );
};

/** Beat punch: scale pulse that decays after each beat (beats in seconds, from beatmap.json). */
export const BeatPunch: React.FC<{beats: number[]; amount?: number; decay?: number; children: React.ReactNode}> = ({
  beats,
  amount = 0.05,
  decay = 11,
  children,
}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = frame / fps;
  let last = -1;
  for (const b of beats) if (b <= t) last = b;
  const pulse = last < 0 ? 0 : Math.exp(-(t - last) * decay);
  return <AbsoluteFill style={{transform: `scale(${1 + amount * pulse})`}}>{children}</AbsoluteFill>;
};

/** White flash on given frames (use on a hit or hard cut). */
export const FlashFrame: React.FC<{atFrames: number[]; length?: number; strength?: number}> = ({
  atFrames,
  length = 5,
  strength = 0.85,
}) => {
  const frame = useCurrentFrame();
  const hit = atFrames.find((f) => frame >= f && frame < f + length);
  if (hit === undefined) return null;
  const o = interpolate(frame - hit, [0, length], [strength, 0], {easing: EASE.out});
  return <AbsoluteFill style={{backgroundColor: '#fff', opacity: o}} />;
};

/** Dev-only overlay that shows the platform UI keep-out zones. Never render it in the final export. */
export const SafeZoneGuide: React.FC = () => (
  <AbsoluteFill style={{pointerEvents: 'none'}}>
    <div style={{position: 'absolute', top: 0, left: 0, right: 0, height: SAFE.top, background: 'rgba(255,0,0,0.25)'}} />
    <div style={{position: 'absolute', bottom: 0, left: 0, right: 0, height: SAFE.bottom, background: 'rgba(255,0,0,0.25)'}} />
    <div style={{position: 'absolute', top: 0, bottom: 0, left: 0, width: SAFE.side, background: 'rgba(255,0,0,0.18)'}} />
    <div style={{position: 'absolute', top: 0, bottom: 0, right: 0, width: SAFE.side, background: 'rgba(255,0,0,0.18)'}} />
  </AbsoluteFill>
);
