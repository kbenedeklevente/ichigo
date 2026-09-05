# P1 camera prototype contracts — proposal v0.1

This packet narrows the [integrated plan](../design/integrated_game_plan.md), [visual roadmap](../design/visual_engine_roadmap.md), and [execution plan](../design/execution_and_delegation.md) to camera, proxies, and targeting. It proposes conventions for integration review; it defines neither implemented APIs nor automated tests. The companion [camera scenarios](fixtures/camera_scenarios.json) are declarative manual/replay specifications. All numeric settings and tolerances are provisional. P1 does not implement inventory, fishing outcomes, weather scheduling, or saves.

## Space, camera, and representation

Use meters, seconds, and a right-handed world: +X right, +Y up, +Z backward. The mean ocean is Y=0. At the initial fixed azimuth, horizontal camera forward is −Z and right is +X. Document angles in degrees; **positive pitch looks down from horizontal**. Thus 0° is horizontal and 90° is overhead. This semantic pitch must be converted explicitly to the chosen engine transform convention rather than copied into an Euler component unchecked.

Start with perspective, 60° vertical FOV, zero roll, fixed azimuth, 20° preferred pitch, and a 12°–52° clamp. Compare a 12°–26° clamp separately. Preserve vertical FOV while resizing between 16:9 and 16:10. A single controller owns framing around a physical anchor; distance/offset calibration should seek 20–30% subject frame height. A 0.5-second preset transition is an experiment, with an immediate reduced-motion alternative. Buoyancy roll must not roll the camera.

Each proxy has a simulation root and visual child. The root owns physical position, heading, collision, buoyancy, and interaction anchors. Billboarding, sprite selection, bounded scale compensation, and deformation affect the visual child only. Apply asset-local deformation before visual orientation/scale, then placement at the world anchor, then view/projection. Record unsupported views. Child/bucket layering must preserve the oversized number 15 jersey without mirroring its lettering. Visual enlargement never enlarges collision or interaction reach.

## Target selection and identity

Pointer rays originate from the actual active camera and current viewport/projection after that frame’s camera update. Controller reticles resolve against the same world surfaces and reach rules. Do not use a stale camera, an enlarged visual card, or a different controller-only range.

For this fixture, reach is horizontal distance from the bucket root’s interaction anchor, with a 12-meter inclusive limit. The ray must hit an eligible surface in front of the camera. Reject skyward and near-parallel ocean rays before intersection; use normalized downward Y greater than 0.0001 and a 200-meter ray travel cap. Reject nonfinite, behind-camera, absent, occluded, or out-of-reach results. A rejected request creates no target and cannot silently clamp to a distant point. Give visible validity feedback.

A target’s stable ID is immutable throughout its lifetime. Selection retains that ID across tilt, resize, proxy transforms, and framing requests. Entity anchors may move through simulation; changing camera never moves them. Committing a point preview snapshots its world position and originating target ID. Subsequent tilt does not reproject that committed point. If an entity becomes unavailable, invalidate selection explicitly; do not replace it with another entity under the cursor. No camera action consumes a world-randomness draw or changes an interaction outcome.

## Shared time and input ownership

Use one ocean sample definition for height, upward normal, and local flow velocity at world X/Z and simulation time. Rendering and buoyancy share its origin, phase, and parameters. If rendering interpolates between ticks, interpolate matching root/sample presentation together. Never advance a separate shader wall clock. The 1-centimeter waterline agreement applies to this direct-follow P1 proxy, allowing its configured waterline offset. Future damped buoyancy may intentionally lag but must share samples.

For P1, one input owner switches among exploration, target preview, and paused UI. UI consumes pointer/controller events before world actions. Exploration steers using normalized camera directions projected onto the ocean plane; preview additionally owns select/commit/cancel. Camera tilt remains available in both unpaused modes. Cancel releases preview ownership. Context framing restores preferred pitch on exit and must respect further tilt input.

Pause/settings freeze simulation time, ocean phase, root motion, and preview changes; only UI navigation continues. Resume discards held/queued commit inputs until released. Freeze world particles/audio if present; UI feedback may continue. These are prototype policies, not a complete interaction framework.

## Acceptance scenarios

- **CAM-01 — Sweep and resize:** compare both ranges/aspects; record sky, clipping, rim/child overlap, target readability, and reduced-motion transitions. High-view horizon loss is evidence for a decision, not an automatic failure.
- **CAM-02 — Reach and ray rejection:** exercise both input paths at/beyond reach, skyward/grazing rays, and occlusion; rejection leaves selection unchanged.
- **CAM-03 — Identity through presentation:** retain selection and committed point while tilting, resizing, and compensating proxies; invalidate a removed target explicitly.
- **CAM-04 — Shared ocean phase:** compare waterline/sample agreement during a deterministic wave and pause/resume; camera changes contribute no physical motion.
- **CAM-05 — Input ownership:** steer through tilt, cancel preview, pause during held commit, and resume; observe one action owner, constant movement speed, and no accidental commitment.
