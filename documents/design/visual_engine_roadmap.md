# Visual engine experimentation roadmap

## Retained visual-density study — 6 September 2026

The user selected the [visual density iteration](../experiments/visual_water_density.md) to keep on its own branch. A 1–8× slider subdivides illustrated tiles and interpolates their movement on the GPU from the unchanged 4 m logical grid. The next branch addresses keeping the curling crests large while retaining smaller water tiles; follow the study for scope and the confirmed original crest spacing.

## Selected direction — Paper Theatre, 6 September 2026

The user chose Paper Theatre from the five art studies. It is merged into main at `1622c52`: independent upright illustrated crest cards plus separate reclining ribbon cards, weather-driven cell motion, and an ink-colored backdrop. There is no shared visible water mesh. Older requirements below for a matching visible substrate are superseded by this choice. The existing invisible gameplay sampler is retained as a documented approximation; fish and fishing integration are secondary now.

Preserve the selected wave drawings and composition while matching Ichigo and the brown bucket to their paper, ink and palette. Next visual priorities are layer cohesion, convincing motion, repetition, camera coverage at 12–52° and bucket framing. See [the selected study](../experiments/variant.md) and [comparison review](../experiments/showcase_review.md).

## Latest correction: raised crests, not horizontal sheets

The user rejected the flat wave appearance in the weather study. The next visual task is the [raised illustrated-wave correction](raised_paper_waves.md): visible front faces, crest lips and upper shoulders on thin curved paper strips, over a matching continuous water surface. The current horizontal-sheet renderer is not an accepted paper-wave representation. This correction takes priority over expanding weather polish or the art library.

## Review update: illustrated panels first

The user selected **12°–52° with no Keep sky option**, requested slightly smaller framing and browner wood, and rejected the solid-looking proxies as the visual direction. Follow the [illustrated ocean and nested weather roadmap](paper_ocean_weather.md) for the next experiment: separate drawings, individual panel motion, and a nearby render grid inside a larger weather simulation. Low-poly, medium-poly and volumetric studies remain available later; they do not block the requested paper study.

## Objective and scope

Find a camera and asset system that supports readable systemic play while giving the ocean and sky a strong presence. Build experiments inside Godot rather than writing a new general-purpose rendering engine. Typed GDScript controls scene logic; materials and shaders handle the chosen stylization. Pin a stable engine version when creating the project, and record the actual Mac chip, memory, renderer, and render resolution with each benchmark.

All numerical settings below are experiment starting points, not validated production specifications.

## Camera geometry first

Define pitch as the optical axis's downward angle from the horizontal: 0° is horizontal, 90° is straight down. Prototype a **12°–52°** range, **20°** starting pitch, **60° vertical field of view**, no roll, and fixed azimuth. Compare 16:9 and 16:10, with a resizing test. Prefer a continuous tilt control with optional comfortable presets. Do not tie the camera to the bucket's wave roll.

In a symmetric perspective view above an ideal flat ocean, the horizon appears only while downward pitch is less than half the vertical FOV. Its approximate normalized vertical position, measured from the top, is:

`horizon_y = 0.5 - tan(pitch) / (2 * tan(vertical_fov / 2))`

This is our geometric derivation for an idealized scene, not a Godot-specific guarantee. It ignores curvature, waves, lens shift, and occlusion. With a 60° vertical FOV:

| Downward pitch | Approximate sky above horizon | Intended test |
|---|---|---|
| 12° | 32% of frame height | Scenic travel; near-target compression risk |
| 20° | 18% | Initial default travel view |
| 26° | 8% | More surface visibility, narrow sky band |
| 38° | Horizon outside frame | Fishing/nearby activity overview |
| 52° | Horizon outside frame | Upper tilt limit and inventory/occlusion stress test |

Raising the camera without changing pitch does not restore the ideal horizon's screen position. Increasing FOV can restore it at some angles, but changes scale and distortion. Avoid silently cropping/compositing a second sky camera as if it were a geometrically continuous view.

Camera review resolved: keep 12°–52° and remove the narrower sky-preserving comparison. The user accepts losing the horizon in higher views. Keep a sky-visible default.

Godot Camera3D supports perspective, orthogonal, and frustum projections and provides screen/world projection methods. Lock the intended aspect behavior so the test really uses a vertical FOV. [Camera3D reference](https://docs.godotengine.org/en/stable/classes/class_camera3d.html)

## Projection alternatives

| Approach | What it tests | Risk / selection rule |
|---|---|---|
| Moderate perspective | Real horizon, natural depth, readable nearby bucket | Leading candidate; tune distance and framing to avoid tiny targets |
| Narrower perspective from farther away | Flatter illustrated composition | Reduced sky at the same pitch; can hide depth cues used for casting |
| Orthographic | Flat asset coherence and stable apparent size | Parallel rays over an infinite plane do not create the desired natural ocean horizon; use as a comparison, not an assumed solution |
| Deliberately composed frustum/backdrop | Persistent sky with an illustrative spatial compromise | Only proceed if ordinary perspective fails; explicitly test target alignment, parallax, and transitions |

Do not interpolate arbitrarily between perspective and orthographic during play in the first experiment. It creates another variable before we understand the camera itself.

## Camera behavior and input

- Aim for the child/bucket assembly to occupy roughly 20–30% of frame height in the first test. Match subject scale when comparing angles. These are framing targets, not gameplay collision sizes.
- Define a fixed physical focus anchor on the bucket/child assembly. Derive camera distance and target offset from a tested pitch profile; do not let independent scripts fight over framing.
- Smooth pitch changes with a bounded transition; keep the horizon level. Prototype a roughly half-second preset transition and a direct continuous control, with reduced-motion settings.
- Use one camera controller that accepts exploration, fishing, and inspection framing requests. Preserve the player's preferred pitch and restore it after a contextual interaction; never silently disable their tilt input.
- Project camera right/forward onto the ocean plane for screen-relative steering. Normalize diagonals, and keep the movement basis stable through pitch changes. Physical speed and heading are independent of zoom.
- Raycast from the actual active camera to valid gameplay surfaces for pointer targeting. Reject rays aimed into sky or beyond reachable distance; do not generate enormous coordinates from near-parallel plane intersections.
- Give controller users a local casting/selection reticle constrained to the same reachable area. Show valid range through diegetic or subtle visual feedback.
- A camera change does not alter the cast's existing world-space target, fish behavior, loot seed, or interaction result. Preserve selected targets by stable ID.
- Near/far clipping, the bucket rim, character occlusion, fish visibility under water, and small-screen targets are acceptance tests at every pitch.

## Flat assets and camera-dependent transforms

Start with cheap flat proxies to expose failures. Separate a world-space simulation root from a visual child. Position, collision, buoyancy, fish headings, interaction anchors, and reward logic belong to the root. Camera compensation affects only the visual representation.

Candidate visual operations: limited billboard rotation, bounded scale compensation, a rigged quad grid for gentle bends, and view-dependent sprite selection. For a visual vertex, the operation order is asset-local deformation → visual scale/orientation → placement at the world anchor → camera view/projection. A fish therefore bends along its local body before being oriented in the world. Document the transform convention per asset; camera compensation never alters the simulation root.

Billboards keep a plane readable, but cannot reveal an unseen bucket interior or turn a painted side view into an anatomically correct top view. A projective warp changes a plane's appearance; it does not recover hidden surfaces, correct self-occlusion, or a different silhouette. Avoid unbounded inverse-cosine scaling near grazing angles.

| Asset | First proxy | Candidate production representation |
|---|---|---|
| Ichigo | A few hand-authored elevation/directional poses on cards | Layered poses or a thin rigged mesh, depending on angle tests |
| Bucket | Separate illustrated rear wall, interior, child layer, front rim/wall | Layered drawings; test extra elevation views and thin support geometry where needed |
| Nearby fish | Flat silhouette with body bend | Elevation-aware sprites or thin/low-poly mesh for credible turning and depth |
| Cloud ribbons | Long cards with subtle deformation | Layered cards or thin meshes; stable silhouettes across the camera range |
| Ocean | Raised illustrated crest assemblies owned by square ground cells | Curved front/lip/shoulder strips above a matching substrate; shared surface sampling and connected motion |
| Tools and line | Simple geometry and a clear line | Physical attachment anchors with representation matching the selected style |

Never mirror the number 15 to manufacture a reverse-facing character pose. If changing directional sprites, use angle thresholds with hysteresis; test crossfades for double images. Character heading must remain readable even if its visual card partially faces the camera.

Godot provides built-in billboard material modes, but their axes and behavior must be checked in the chosen version. Layered transparency can sort incorrectly; compare opaque cutout geometry and alpha scissor before relying on stacks of alpha-blended cards. [BaseMaterial3D](https://docs.godotengine.org/en/stable/classes/class_basematerial3d.html), [Rendering limitations](https://docs.godotengine.org/en/stable/tutorials/3d/3d_rendering_limitations.html)

## Matched aesthetic experiments

Use the same camera poses, geometry scale, poses, light direction, ocean motion, target placement, resolution, and short input recording. Change one representation at a time. Render a calm sky-visible view, a high interaction view, a full tilt transition, a cast, and an animal moving behind the bucket for each candidate.

| Variant | Experiment | What to judge |
|---|---|---|
| A. Flat paper | Layered illustrated cards with controlled transforms | Cohesion, exposed edges, angle-dependent distortion, authoring cost |
| B. Dimensional paper | Thin extrusions, gentle folds, visible edges, matte grain | Tactility and stable depth; avoid heavy embossing and ocean terraces |
| C. Low-poly | Deliberate broad facets and simplified silhouettes with faded palette | Clear forms at small scale, calm highlights, child and wildlife motion |
| D. Medium-poly | Smoother silhouettes and more deformation geometry with restrained materials | Better close-up motion and bucket interior; avoid drifting into generic glossy realism |

Low/medium poly are geometry and silhouette experiments, not different color identities. Keep the Hokusai-reference palette, cloud rhythm, calm water, and child/bucket scale consistent. Establish actual per-asset geometry and texture budgets after profiling; polygon count alone does not predict cost when transparency and overdraw dominate.

Volume is an independent experiment axis. First test physical thickness in paper forms. Then compare ordinary atmospheric haze with sparse volumetric fog. Finally consider actual volumetric clouds only if they serve the selected style and run well. Godot's built-in volumetric fog requires Forward+; it does not automatically supply our authored cloud shapes. [Volumetric fog](https://docs.godotengine.org/en/stable/tutorials/3d/volumetric_fog.html)

## Earlier comparison roadmap

The ordered next tasks are now in [paper ocean and weather](paper_ocean_weather.md#ordered-implementation-plan). The table below retains the broader experiments for later review.

| Task | Output | Exit condition |
|---|---|---|
| R0: Camera geometry | Proxy scene, pitch controls, horizon/frame captures, screen/world targeting | We understand the sky-versus-overview tradeoff at the target aspect ratios |
| R1: Flat-asset feasibility | Bucket layers, child poses, fish, cloud card with transform controls | Failure angles and minimum extra views/geometry are documented |
| R2: Aesthetic comparison | A/B/C/D matched short captures | User selects a candidate or a specific hybrid to test |
| R3: Water and cohesion | Moving ocean, bucket response, stable paper/poly material set | No gaps, sliding grain, clipping, or unreadable water/animal overlap |
| R4: Interaction camera | Cast/inspect/return with reachable-target preview | Continuous input and stable target alignment at all supported angles |
| R5: Environment transitions | Daylight/overcast/dusk previews, fog quality toggle | Smooth readable transitions with the same art identity |
| R6: Performance and decision | Frame-time captures, quality ladder, chosen camera/asset contract | Supported range and minimum quality are explicit before asset production expands |

Target 60 fps at an agreed internal resolution on the actual Mac; report measured frame times and the expensive passes. Do not claim the generated images establish runtime quality. Keep a fallback without volumetric effects. The tests must remain readable with reduced motion and at the chosen lowest quality setting.

## Deliverables and decision record

Produce an editable test scene, source assets, preset resources, comparable motion captures, an issue list, and a short record of the winning camera/representation choices. Include supported pitch/yaw, projection, target scale, asset view coverage, occlusion/shadow policy, water visibility rules, and performance conditions. Unrestricted camera yaw and first-person views are separate later gates.
