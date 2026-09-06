# Paper Theatre wind and visual motion

6 September 2026. Vertical-motion gain and weather-driven drawing height are implemented. Lateral oscillation still awaits clarification. Saved baseline: commit `9c01864`, pushed tag `paper-theatre-before-wind-motion`.

## Current crest curve and weather tiers — 6 September 2026

The [five-level weather amendment](five_level_weather.md) supersedes the linear crest curve below: five levels per axis, 0.35× calm crests and a reversed-logarithmic rise to 2× at the new combined maximum. Ribbon coverage and doubled spring motion remain unchanged.

## Current vertical-motion adjustment

The user confirmed doubling upward and downward movement around the existing resting position. `weather_presentation.gd` now multiplies the signed spring height by 2 for both crest and ribbon roots. This motion gain preserves rocking, animation phase/speed and physical weather fields. The subsequent drawing-size adjustment below independently scales the art and its submerged offsets. This is a presentation gain, not the pending lateral oscillator or a new wind profile. The invisible gameplay surface remains the existing approximation; the bucket’s physical bob is not doubled. Verification: the existing rendered weather-scene suite passed 19 checks including three captures. Root inspected strong-weather captures at 20° and 52° for layer coverage and bucket readability; this is a sampled visual check, not acceptance of every animation phase.

## Weather-driven drawing height

The user chose **half original height in calm → twice original height at maximum combined wind and storm strength**, preserving width. This supersedes the earlier inverse-size suggestion; there is no division by zero in calm conditions.

`height_scale = lerp(0.5, 2.0, clamp((wind_intensity + sky_strength) / 6.0, 0.0, 1.0))`

Both coordinates range continuously from 0 to 3. Wind uses the base scalar field and profile anchors 0.12/1.8/5/9; sky severity uses base cloud cover at the sunny/cloudy/raincloud/storm anchors 0.12/0.65/0.88/1.0. Each contributes equally. Sunny calm gives 0.5×; sunny strong wind gives 1×; maximum storm sky and wind give 2×. The rendered subset exports these local coordinates, so front arrival and clearing change drawing height smoothly across cells. Physical force, chance weights and weather timing are not changed.

Scale world Y around each cell's moving waterline for both crest and ribbon: multiply the drawing basis's vertical component and its submerged root offset by the height factor, then add the existing 2× signed spring displacement. Preserve world X/Z width and depth, including the reclining ribbons' overlap. This avoids sinking a half-height drawing below its old submerged root or shortening the ribbons' depth coverage. Drawings remain original SVGs; the invisible gameplay sampler and bucket physics retain their documented approximation.

Verification: 18 paper-card checks, 19 rendered weather-scene checks (including three captures), and 108 scheduler/chance regression checks passed. Root inspected calm 20° and strong/rain 52° captures for coverage and bucket readability. Full storm animation remains subject to user visual review.

## Accepted intent

- Preserve Paper Theatre. Its current curling-wave appearance is the reference for wind intensity **2**, a turbulent sea.
- Drive faster horizontal sway and vertical movement from wind.
- Add a wind-intensity matrix ranging from 0 to 3. At 0 the wave drawings should be still.
- At intensity 1, the user described 0.5 units of sideways oscillation once per second; 2 as left/right within a second; 3 as left/right/left per second. The exact frequency and travel convention require confirmation before implementing.
- Keep visual motion distinct from the physical weather/swell solver. Fish remain secondary.
- Remove the isolated cream teardrop decorations from the wave SVGs. This independent artwork fix is implemented; see [cleanup notes](../experiments/wave_droplet_cleanup.md).

## What exists now

The renderer updates 289 upright crest cards and 289 reclining ribbon cards from the surrounding 33×33 weather simulation. There is no shared visible ocean mesh. Crest/ribbon X/Z anchors are currently fixed within their world cells; vertical motion follows the existing spring field with a 2× presentation gain, and drawing height follows the local weather scale above. Rocking retains its original response. The shader masks drawings inside the bucket.

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
