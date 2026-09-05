# P1 contract and scene integration runners

The focused runner is [camera_contract_tests.gd](../../game/tests/camera_contract_tests.gd). It extends `SceneTree`, preloads the real camera and ocean scripts by resource path, and collects failed checks before exiting with status 1. Success exits with status 0. It does not require a generated global-class cache or an independent fake implementation.

From the repository root, run the installed Godot binary with:

```sh
godot --headless --path . --script game/tests/camera_contract_tests.gd
```

Use the actual binary path if `godot` is not on `PATH`. The verified engine is now installed at `/Applications/Godot.app/Contents/MacOS/Godot`. The integration owner provided the engine; this packet did not install it.

## Covered contracts

- **CAM-01 subset:** initial pitch, immediate pitch clamps, and switching between the wide and sky comparison profiles. The camera is added to the live scene tree before these checks.
- **CAM-02 subset:** valid finite plane hits, horizontal 12-meter inclusive reach versus 12.1 meters, translated interaction anchors, rejection of sky/parallel/grazing/zero/nonfinite rays, behind-camera intersections, and the 200-meter ray travel cap.
- **CAM-04 subset:** analytic wave phase, documented crest/trough/zero samples, spatial and temporal periodicity, upward unit normals perpendicular to the sampled surface, and zero advective flow. The normal check measures neighboring heights rather than duplicating the normal implementation.
- **CAM-05 subset:** zero input, equal cardinal/diagonal magnitude, horizontal steering through the pitch range, correct fixed-azimuth directions, and honoring a rotated camera basis. The rotated basis is a helper contract check, not approval for player-controlled yaw.

The runner reads schema version and horizontal reach from [the declarative fixture](fixtures/camera_scenarios.json). Other explicit expected values are the documented P1 baseline. A deliberate wave, range, or pitch-profile change requires reviewing the fixture, contract, and tests together. This runner does not automatically execute the fixture's action descriptions.

## Actual scene integration

[scene_integration_tests.gd](../../game/tests/scene_integration_tests.gd) loads the actual `camera_study.tscn`, waits for scene frames, and invokes its real input handler. It verifies:

- The study's camera is the viewport's active camera. Unprojecting a known water point and committing through the controller-cursor path yields a finite hit on that camera ray and the sampled wave surface.
- Committing creates marker and line geometry. The committed world point survives immediate 12°/52° tilt and an actual viewport change from 1280×800 to 1280×720.
- The direct-follow bucket waterline matches the shared ocean sample before and after camera changes and resume.
- Pause freezes simulation time, bucket root transform, and the ocean material's simulation-time parameter across scene frames.
- A held commit remains suppressed through pause and resume while preserving the legitimate existing target. Releasing it permits a fresh commitment to a distinct water point.
- Cancel clears committed state, hides the marker, and removes line geometry on a following frame.

Run it from the repository root:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script game/tests/scene_integration_tests.gd
```

The runner uses `Input.action_press`/`action_release` for held state and direct `InputEventAction` handler calls. It does not simulate physical devices or GUI event propagation. It collects failed checks and exits with status 1 on failure, 0 on success.

## Separate acceptance work

These headless checks do not establish horizon appearance, framing quality, occlusion behavior, proxy layering, or rendered visual quality. The scene runner verifies selected projection and state paths, while physical pointer/controller parity, GUI input ownership, entity target identity/invalidation, transition smoothing, and rendered water/buoyancy agreement remain manual/replay acceptance work. In particular, verifying the shader's phase parameter does not prove its rendered vertices use that parameter correctly.

P1's 1-centimeter waterline agreement is a direct-follow proxy check. It is not an instantaneous-height requirement for future damped physical buoyancy. No performance, gameplay, or visual acceptance pass is implied by this runner.

## Execution record

On 2026-09-05, the integration owner executed the runner against the actual project with official Godot `4.7.2.stable.official.ed1daf0bf` after verifying its code signature:

```sh
work/runtime/Godot.app/Contents/MacOS/Godot --headless --path . --script game/tests/camera_contract_tests.gd
```

Reported output: `PASS: 123 P1 camera/ocean contract checks. Visual and scene interaction acceptance remains separate.` Process exit status: **0**. No visual acceptance checks had been performed at this checkpoint.

After the same verified engine was moved to `/Applications/Godot.app`, the test author executed the actual-scene runner on 2026-09-05 using the command above. Output: `PASS: 34 actual-scene P1 integration checks. Rendered appearance and hardware-input routing remain separate.` Process exit status: **0**. This result covers the scene integration subset described here and makes no visual acceptance claim. The earlier `work/runtime` engine path is historical and no longer exists.
