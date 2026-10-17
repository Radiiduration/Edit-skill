// 3D hero shot: glossy object + orbiting camera + studio lighting. Fully frame-driven.
// Rules from Remotion's 3D guidance: wrap in <ThreeCanvas width height>, add lights, and NEVER use
// useFrame() or self-running animations (they flicker in renders). Drive everything from useCurrentFrame().
import React from 'react';
import {interpolate, useCurrentFrame, useVideoConfig} from 'remotion';
import {ThreeCanvas} from '@remotion/three';
import {useThree} from '@react-three/fiber';
import {COLOR, EASE} from './tokens';

const CameraRig: React.FC<{position: [number, number, number]; target?: [number, number, number]}> = ({
  position,
  target = [0, 0, 0],
}) => {
  const {camera} = useThree();
  camera.position.set(position[0], position[1], position[2]);
  camera.lookAt(target[0], target[1], target[2]);
  camera.updateProjectionMatrix();
  return null;
};

export const Hero3D: React.FC<{accent?: string; orbitSeconds?: number}> = ({accent = COLOR.accent, orbitSeconds = 3}) => {
  const frame = useCurrentFrame();
  const {width, height, fps} = useVideoConfig();
  const t = frame / fps;

  // Eased camera push + partial orbit (never linear).
  const orbit = interpolate(t, [0, orbitSeconds], [-0.7, 0.5], {
    easing: EASE.inOut,
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const dist = interpolate(t, [0, orbitSeconds], [8.5, 5.6], {
    easing: EASE.out,
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const cam: [number, number, number] = [Math.sin(orbit) * dist, 0.9, Math.cos(orbit) * dist];

  return (
    <ThreeCanvas width={width} height={height} camera={{fov: 32, position: cam}}>
      <CameraRig position={cam} />
      <color attach="background" args={[COLOR.ink]} />
      <ambientLight intensity={0.25} />
      <hemisphereLight args={['#bcd3ff', '#1a1208', 0.6]} />
      <directionalLight position={[5, 6, 4]} intensity={2.2} />
      <directionalLight position={[-6, 2, -4]} intensity={1.4} color={accent} />
      <pointLight position={[0, -3, 3]} intensity={30} color={accent} />
      <mesh rotation={[t * 0.5, t * 0.8, 0]}>
        <torusKnotGeometry args={[1, 0.32, 220, 32]} />
        <meshPhysicalMaterial color={accent} metalness={0.85} roughness={0.2} clearcoat={1} clearcoatRoughness={0.1} />
      </mesh>
    </ThreeCanvas>
  );
};
