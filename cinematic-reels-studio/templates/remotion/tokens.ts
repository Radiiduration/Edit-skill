// Design tokens: define once, import everywhere. Never hard-code colours, easing or timing in components.
import {Easing} from 'remotion';

export const FPS = 30;
export const W = 1080;
export const H = 1920;

// Platform UI keep-out zones in px for a 1080x1920 Reel (top 12%, bottom 25%, sides 6%).
export const SAFE = {
  top: Math.round(H * 0.12),
  bottom: Math.round(H * 0.25),
  side: Math.round(W * 0.06),
} as const;

export const COLOR = {
  ink: '#0B0B0D',
  paper: '#F5F1E8',
  accent: '#FF5A1F', // ONE accent colour per video: change here only
  glow: 'rgba(255,90,31,0.35)',
} as const;

export const TYPE = {
  display: '"Inter Tight", "Inter", "Helvetica Neue", Arial, sans-serif',
  weight: {display: 800, body: 500},
  tracking: {display: '-0.03em', caps: '0.14em'},
  size: {hook: 132, caption: 92, small: 44},
} as const;

// Ease-out for entrances, ease-in for exits. Never linear.
export const EASE = {
  out: Easing.bezier(0.16, 1, 0.3, 1),
  in: Easing.bezier(0.7, 0, 0.84, 0),
  inOut: Easing.bezier(0.65, 0, 0.35, 1),
} as const;

export const SPRING = {
  snappy: {damping: 18, stiffness: 220, mass: 0.7},
  pop: {damping: 12, stiffness: 260, mass: 0.6}, // slight overshoot for key words
  soft: {damping: 26, stiffness: 120, mass: 1},
} as const;

export const STAGGER_FRAMES = 3; // 2-4 frames between element entrances
