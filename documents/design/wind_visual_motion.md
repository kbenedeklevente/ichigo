# Paper Theatre wind and visual motion

6 September 2026. User-directed next study; technical audits completed, animation implementation pending clarification. Saved baseline: commit `9c01864`, pushed tag `paper-theatre-before-wind-motion`.

## Accepted intent

- Preserve Paper Theatre. Its current curling-wave appearance is the reference for wind intensity **2**, a turbulent sea.
- Drive faster horizontal sway and vertical movement from wind.
- Add a wind-intensity matrix ranging from 0 to 3. At 0 the wave drawings should be still.
- At intensity 1, the user described 0.5 units of sideways oscillation once per second; 2 as left/right within a second; 3 as left/right/left per second. The exact frequency and travel convention require confirmation before implementing.
- Keep visual motion distinct from the physical weather/swell solver. Fish remain secondary.
- Remove the isolated cream teardrop decorations from the wave SVGs. This independent artwork fix is implemented; see [cleanup notes](../experiments/wave_droplet_cleanup.md).

## What exists now

The renderer updates 289 upright crest cards and 289 reclining ribbon cards from the surrounding 33×33 weather simulation. There is no shared visible ocean mesh. Crest/ribbon X/Z anchors are currently fixed within their world cells; vertical positions and rocking follow the existing spring field. The shader masks drawings inside the bucket.

The current runtime starts with calm wind despite the visually turbulent artwork. Calm still uses strength 0.12, target amplitude 0.12 m and phase speed 0.65 m/s. Therefore the new appearance/intensity mapping and stillness at level 0 are changes, not descriptions of current behavior.

## Recommended implementation boundary (proposal)

Keep the physical wind vector and its units for direction, rain, clouds and local event modifiers. Add a separately authored continuous `wind_intensity` in [0,3]; stable weather profiles can use 0/1/2/3 and transitioning cells interpolate through fractional values. Do not infer intensity solely from vector length: opposing wind directions can cancel during a transition.

Export intensity and animation phase with panel state, then let a small visual response table control horizontal amplitude/frequency and vertical amplitude/frequency. The renderer consumes those values to transform illustrations. Do not speed up the entire world or repurpose physical metres/second as an animation frequency.

Integrate motion phase using the simulation clock: `phase += TAU * frequency_hz * dt`. Preserve phase through changing wind, pause/resume, snapshots and grid scrolling. Recomputing phase as current speed multiplied by total time would jump during transitions. If each cell must move at its local frequency, store/integrate phase per cell; a single global phase with spatial offsets does not provide different local frequencies.

Keep the existing slow physical swell while adding bounded decorative motion. The current heavily damped springs will not reproduce a fast target displacement simply by increasing their forcing speed. Gate the existing visual height/tilt response as well as the new oscillator if level 0 must leave all wave art still. That does not mean freezing weather fronts, simulation time or the rest of the game.

Keep lower ribbons more coordinated than crests, so their coverage remains reliable. Large unrelated vertical excursions could expose gaps and make the approximate gameplay waterline more noticeable. Vertical amplitude, frequency relationship and exact crest/ribbon phase policy remain provisional.

## Coverage evidence

- Cells are 4 m wide. Crest quads are 6.8 m wide, giving 2.8 m rectangular overlap. If adjacent crests each move 0.5 m away from one another, 1.8 m remains.
- Ribbon quads are 8.024 m wide, with 4.024 m rectangular lateral overlap; the same opposing shifts leave 3.024 m.
- Those are rectangular bounds, not guarantees about the transparent drawing silhouettes.
- Ribbons recline through about 5.723 m of full-quad depth. Their common fully painted strip spans only about 3.917 m horizontally, so they do not form a watertight horizontal surface by themselves. At the supported 52° camera this strip has roughly 1.014 m of projected overlap before spring/tilt differences. Existing fixed-camera coverage and overlap must be preserved in motion.
- Existing bucket masking uses final world positions; keep this true after adding offsets. Expand culling bounds if the proposed displacements exceed them.

## Pending user clarification

1. Does intensity 1/2/3 count **one-way sweeps** or **complete back-and-forth cycles per second**? At intensity 2 these give 1 Hz or 2 Hz respectively. The user's left/right wording must not silently select one.
2. Does 0.5 units mean **±0.5 m around the resting position** or **0.5 m total left-to-right span**?

Further motion choices to present with the clarified preview: vertical travel and its rhythm, whether lateral sway follows the fixed drawing axis or wind direction, and how much lower ribbons share the crest motion. No unanswered design question is resolved by elapsed time.

## Next verification

After clarification, build a bounded visual-motion study. Check phase continuity, local wind differences, scrolling into negative cells, save/replay, pause, intensity transitions and settling to stillness. Capture moving maximum/opposing offsets at 12°,20°,38°,52°; inspect ribbon gaps, bucket cutout and silhouette coherence. The numerical overlap audit is evidence for feasibility, not visual acceptance of an animation that has not yet been built.
