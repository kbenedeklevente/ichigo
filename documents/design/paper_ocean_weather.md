# Illustrated ocean panels and nested weather simulation

Status: user direction recorded 5 September 2026, followed by an executable weather/event study. Camera/framing changes, the shared event director, nested weather fields, connected panel springs and an initial drawn-water renderer are implemented. See [runtime parameters and limits](weather_runtime_parameters.md) and the [shared event system](event_system.md). This document retains the broader roadmap; final art and production optimizations remain unfinished. Unanswered future design questions stay pending until the user replies, without a timeout or default selection.

## Flat-wave review correction

The implemented horizontal sheets missed the intended raised wave faces. Follow the [raised-paper-wave plan](raised_paper_waves.md) next. Square simulation cells own irregular illustrated crest assemblies; they do not force artwork to lie flat. The existing spring/weather foundation remains useful, but the surface representation and shared crest sampling must be corrected before calling the water visually coherent.

## Confirmed direction

- Keep the full 12°–52° camera range; remove Keep sky. The horizon may leave the frame at higher angles.
- Make the bucket slightly smaller on screen and browner. The first adjustment increases camera distance from 9.4 to 10.2 m, preserving the giant-bucket/young-child proportions and physical reach.
- Replace the solid-looking proxies with individually drawn, layered forms. The current bucket/child meshes have not passed the art gate.
- Water consists of individually moving illustrated panels. Panels stay visually cohesive without requiring every drawn crest or edge to align perfectly.
- Keep the player at the center of a local coordinate system. Render a nearby subset of a larger simulated grid. Each ground cell has equal side lengths.
- Weather events develop outside the nearby region and close in over the player. Direction alone must not bypass the progression schedule.
- Sky categories: sunny, cloudy, raincloud, storm. Wind categories: calm, breeze, strong, storm. Wind-driven wave motion becomes faster before the sea grows taller.
- Simulate cloud cover/movement, sun and lighting, rain, wind, and wave height. Include coherent day/night and weather transitions.

These decisions supersede earlier camera comparison and continuous-water-only proposals. Low-/medium-poly and volumetric alternatives stay in the backlog, but the next visual study prioritizes illustrated layers.

## Reference research and visual translation

Team Lazerbeam's art-test account describes **2D illustrations placed in 3D space**, with lighting, color and animation developed through a dedicated visual study. This supports using spatial depth without making the visible objects look like solid sculpted models. The source does not establish how its renderer or physics works internally. [Developer art-test account](https://teamlazerbeam.itch.io/shroom-and-gloom-jam/devlog/745144/announcement-things-are-happening-with-shroom-and-gloom), [official game page](https://teamlazerbeam.itch.io/shroom-and-gloom).

The user's water screenshot supplies a different reference: repeated overlapping crest silhouettes, patterned faces, and visible separation between wave layers. Translate that rhythm into Ichigo's faded indigo, blue-green, ivory, and parchment palette; retain the original horizontal cloud inspiration. Do not copy the screenshot's artwork or the Great Wave's giant crest.

Proposed asset set for the next study: several original small wave drawings, separate rear bucket wall/interior/front rim layers, a child illustration with oversized jersey 15, a fish silhouette, and cloud ribbons. Test all at 12°, 20°, 38°, and 52°, plus continuous motion. Individual paper edges should be visible, but opaque backing/overlap should prevent accidental holes through the sea. Maintain common grain scale, line weight, palette roles, lighting response, and bounded height variation.

Square **ground cells** do not require square visible drawings. Each cell can host one or more irregular cutout cards that overlap its footprint. Cards may bend and tilt, with bounded camera compensation where required. A side drawing cannot acquire a convincing top surface through a mathematical warp alone; use additional illustrated layers/views where the camera exposes them. Choose the final layer construction after a small in-engine review, before producing the full asset set.

## User decisions, now resolved

1. Sky and wind may mix independently. The study catalog includes all16 combinations.
2. Panels remain connected, with individual spring motion. Loose colliding pieces are excluded from this implementation.
3. Use authored main-story triggers and chance-based side/achievement opportunities. Both activation methods can apply to any event domain. Triggered or chance weather approaches from a seeded random direction and centers over the player. Activation does not automatically complete a quest or determine a fishing/puzzle outcome.
4. The user delegated initial weather parameter definition. Current values are documented in [runtime parameters](weather_runtime_parameters.md); these are tunable study values rather than finalized pacing or danger settings.

## Coordinates and nested regions

Use horizontal grid coordinates `(x, z)` in Godot; vertical height is `y`. These correspond to the user's two-dimensional matrix axes. Let cell side length be `s`:

`cell_id = (floor(world_x / s), floor(world_z / s))`

`render_position = logical_position - player_logical_position`

Keep stable logical coordinates and IDs alongside player-centered rendering coordinates. Moving the player shifts the local origin; it must not reseed cells, teleport a visible front, reroll encounters, or move a committed fishing target relative to the water. Store fractional travel separately from whole-cell buffer shifts. Rebase all visible anchors consistently.

Define nearby rendering bounds `R = [-rx, rx] × [-rz, rz]` and simulation bounds `S = [-sx, sx] × [-sz, sz]`, with `sx > rx`, `sz > rz`. All cells are square even if the overall window is rectangular. `R` is strictly a subset of `S`.

| Region | State/work | Visual representation |
|---|---|---|
| Nearby R | Shared weather fields, wave samples, detailed panel dynamics, interaction actors | Illustrated water panels, local clouds/rain, bucket and encounters |
| Surrounding S minus R | Weather evolution, front movement, cheaper wave envelope and retained panel state | No detailed per-cell artwork; distant weather may contribute to an aggregate backdrop |
| Beyond S | Compact event/front descriptors and seeded boundary conditions | No detailed simulation or per-cell rendering |

Low camera angles see beyond any practical near grid. A cheap horizon/sky backdrop must represent that distance, otherwise the ocean will end visibly at R. Proposed backdrop samples aggregate distant weather and blends with the panel region; it does not instantiate all distant cells. Preview this transition explicitly. Camera frustum culling may reduce drawings inside R but must never change simulation results.

Use reusable ring buffers with stable logical cell IDs. Shift only entering/leaving rows and columns. Preserve overlapping values and initialize new borders from continuous boundary fields and active fronts. Retain referenced actors/line endpoints separately from decorative panel residency. Test rapid movement and reversal across positive and negative cell boundaries.

## Matrices and shared environment state

Packed arrays indexed by `i + width * j` can represent the matrices. Spatial fields need interpolation between cells so weather does not look like checkerboard tiles.

| Quantity | Stored or derived state | Visible consequence |
|---|---|---|
| Clouds | Cover, optical density, advection/offset and front weight | Ribbon density, cloud shadows, horizon obscuration |
| Wind | Horizontal vector, gust state, target strength | Cloud drift, rain slant, small wave response |
| Rain | Local intensity and smoothed onset/decay | Nearby particle density and water impact marks |
| Waves | Amplitude envelope, propagation direction and continuous phase; height/normal sampled from these | Coherent moving water, bucket response, targeting surface |
| Panels | Individual displacement/velocity, tilt/angular velocity, bounded deformation and stable variation seed | Each drawing responds with its own lag and movement |
| Sun/light | Global time phase and sun direction; cloud attenuation sampled locally | Continuous daylight/night and weather darkening |

Not every quantity needs a separate full-resolution matrix. Sun direction is global; local illumination derives from it and cloud density. Cloud art needs altitude/layers above the ground grid. Rain droplets exist only in the visible/local effect volume. These are a deliberately simplified environmental model, not atmospheric fluid simulation.

Use one authoritative environment snapshot per simulation tick. Ocean rendering, panel motion, buoyancy, line targeting, fish conditions, and later sound sample it. Shader animation must not run on an unrelated wall clock. Pause/resume and save state preserve phase, front progression, and random streams.

## Weather states and natural transitions

The following preserve the earlier comparison examples. **They are not mandatory pairs:** the user approved independent axes. Authoritative independent values are in [runtime parameters](weather_runtime_parameters.md). Day/night is a separate continuous cycle, not a fifth weather category.

| Sky / wind | Clouds and light | Rain | Water response |
|---|---|---|---|
| Sunny / calm | Sparse pale ribbons; direct sun readable | None | Low, slow movement |
| Cloudy / breeze | Coverage builds; softer direct light | None by default | Small faster motion, modest height increase later |
| Raincloud / strong | Denser darker layers; reduced direct light | Rising local rain after front arrival | Faster surface response first, height builds with sustained wind |
| Storm / storm | Dense layered sky; marked but readable darkening | Stronger rain | Strongest approved response; storm height/danger require a separate preview |

Raincloud can have an approach phase before rain reaches the player. Lightning/thunder are not automatically included by the word storm. Mist from the older roadmap remains a later optional effect.

Proposed transition sequence: distant formation → approach → local onset → established weather → clearing → residual swell. These are phases of a weather event, not instantaneous biome switches. Each field has its own response rate: cloud density affects light as it arrives; wind changes motion promptly; rain has a spatial leading edge; wave height builds more slowly. On clearing, rain and cloud density decrease while the sea may remain unsettled. Reverse or interrupt transitions from their current values, not from a hardcoded preset start.

Represent an active front with stable ID, origin, direction, extent, falloff, progress and target conditions. Rasterize its smooth influence into S. Make the incoming cloud bank legible in the distance before local rain/wind intensify. The requested eventual arrival needs an explicit director policy: a broad advancing front or expanding weather region can cover the player's travel envelope without visibly snapping or turning to chase them. The user approved guaranteed player-centered arrival. The initial solver uses a player-relative decaying offset, documented in the runtime plan; ordinary advection alone would not guarantee arrival.

For a scalar target response, a candidate update is `q += (target - q) * (1 - exp(-dt / tau))`, using a shorter response time for surface speed than amplitude. Integrate wave phase over time: `phase += omega * dt`. Recomputing phase as `omega(now) * total_time` would cause jumps when wind changes. Use spatially coherent phase/direction fields, not independently randomized oscillators per cell. Treat quicker motion before taller waves as the requested stylized response, not a claim about exact ocean dispersion.

## Individual panel physics proposal

The approved connected panels each have real dynamic state, with restoring force toward a sampled water surface, damping, wind forcing, and bounded coupling to its neighbors. A candidate height-offset equation is:

`acceleration_i = stiffness * (target_height_i - height_i) - damping * velocity_i + neighbor_coupling * laplacian(height)_i + wind_force_i`

Add analogous bounded tilt/bend responses. Use consistent units and an integration method/time step validated for the selected stiffness and mass. Do not choose arbitrary spring coefficients and assume stability. Shared underlying wave motion supplies coherence; individual dynamics add small differences in phase and deformation. Distant cells retain cheaper state and are promoted smoothly before becoming visible.

This is a custom physical solver inside Godot, without requiring one colliding rigid body per water drawing. If the user wants loose pieces, revisit collisions, seams, buoyancy, and performance before implementing. Loose-body separation substantially changes both appearance and water interaction semantics.

Paper ornament may deviate slightly from the gameplay water surface. Large displaced crests must be reflected in the authoritative height/normal samples used by the bucket and targeting; do not let the bucket float through prominent visible waves. Maintain dry bucket masking and layered rim occlusion at every camera pitch.

## Resource efficiency and validation

Start with CPU packed arrays and a fixed simulation step, interpolate visible state between ticks, and profile before moving the solver to GPU or native code. Keep coarser weather updates separate from higher-frequency near-panel motion. Use bounded allocations, pooled cards, shared materials/atlases and spatial batches; avoid a script, collider, and unique material for every cell.

Godot MultiMesh is a candidate for repeated panels. Its instances are culled as a group, so use spatially bounded batches rather than one enormous world batch. Measure transparency overdraw as well as draw calls. [Godot MultiMesh guidance](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html). Check shader/instancing details against the pinned Godot version during implementation.

Record simulated cells, rendered cells, active panels, CPU simulation milliseconds, GPU/frame time, memory and spikes when scrolling. Numerical sizes/rates remain benchmark inputs, not promised budgets. Weather decisions must remain the same with detailed rendering disabled or at a different quality level.

## Ordered implementation plan

1. **Feedback applied:** remove Keep sky, retain 12°–52°, slightly smaller framing and browner bucket. Run camera/scene checks and inspect captures.
2. **Resolved:** independent sky/wind, connected springs, shared triggered/chance activation, and player-centered weather arrival.
3. **Raised-wave correction first:** replace the rejected horizontal SVG sheets with the curved illustrated crest/substrate study; then replace the remaining solid child/bucket proxy appearance; review layered bucket/child, several water panels and cloud ribbons across the camera range. Keep water calm. Do not build a whole asset library yet.
4. **Nested-grid study (foundation implemented):** configurable square cells, strict R subset S, stable scrolling IDs, matrices displayed with debug colors, no costly distant drawings. Verify movement/reversal/rebase continuity and retained targets.
5. **Connected panel study (foundation implemented):** review the approved spring physics, first under constant conditions, then a wind ramp. Review visible seams, ocean continuity, paper motion and motion comfort.
6. **Incoming transition (foundation implemented):** review the implemented weather/front policy and render cloud, light, wind, rain and wave responses together. Show faster motion before increased height and residual swell after clearing.
7. **Complete approved weather presets and time preview:** separate weather darkening from time of day; review day/night readability and select timing with the user. Add gameplay consequences only after agreement.
8. **Profile and integrate:** compare paused/static/moving/front-arrival cases on the M2 Mac; test camera extremes, rendering disabled, cell-border reversals, multiple seeds, active fishing targets, save/resume and reduced quality. Then divide implementation into bounded agent tasks around the agreed interfaces.

Acceptance requires an in-engine motion review, not just an attractive still: no exposed grid boundary, reseeded visible patterns, abrupt front relocation, phase jumps, unbounded oscillation, ocean holes, or camera-dependent weather results. Current gameplay tests do not validate these future systems.
