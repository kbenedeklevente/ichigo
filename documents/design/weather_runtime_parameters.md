# Weather runtime parameters and first study

Status: implemented study parameters, 5 September 2026. The user authorized initial parameter definition. These values are editable art/game tuning, not measured real-world forecasts or final pacing.

## Run and inspect

```sh
./scripts/run_game.sh -- --weather-study
```

The original camera study remains available without the flag. Weather-study mode adds drawn water sheets, connected spring motion, incoming weather, local rain, cloud/lighting changes and the generic event director. The solid child/bucket proxies still require their separate illustrated-asset replacement; this mode does not represent final art approval.

Use1/2/3/4 for sunny/cloudy/raincloud/storm sky and5/6/7/8 for calm/breeze/strong/storm wind. Each key requests the complete last-selected pair. Requests queue behind an active front; repeated active/queued/cooling-down combinations are rejected. Chance events also occur automatically from seed15. Pause freezes the director, weather, water and rain. Existing camera/movement controls remain available.

## Independent sky and wind profiles

Sky controls cloud density, rain and light attenuation; it does not silently force wind strength. Wind controls the local vector and water response independently.

| Sky | Cloud cover 0–1 | Rain intensity 0–1 | Direct-light factor |
|---|---:|---:|---:|
| Sunny | 0.12 | 0 | 1.00 |
| Cloudy | 0.65 | 0 | 0.73 |
| Raincloud | 0.88 | 0.58 | 0.49 |
| Storm | 1.00 | 1.00 | 0.26 |

| Wind | Vector strength, study units/s | Target wave amplitude, m | Wave phase speed, m/s |
|---|---:|---:|---:|
| Calm | 0.12 | 0.12 | 0.65 |
| Breeze | 1.80 | 0.24 | 1.00 |
| Strong | 5.00 | 0.48 | 1.70 |
| Storm | 9.00 | 0.78 | 2.50 |

Amplitude is displacement from mean level, not crest-to-trough height. The two-component wave and spring response determine the actual sample. The reference wavelength is24m, with a smaller secondary component. Wave orientation uses a fixed world basis in this first solver; instantaneous wind changes do not rotate an entire existing wave field.

Response time constants: local wind vector and wave speed2s; cloud/rain/light3s; amplitude10s. Each uses exponential response, so speed responds before height. Clearing preserves residual wave energy. Phase is integrated through speed changes; it is never reset or recomputed as current speed times total elapsed time.

Sun phase is global, separate from cloud attenuation. `day_phase=0.25` and `day_period_s=0` hold daylight for the first visual study. A nonzero period exercises continuous brightness, with a0.18 minimum light factor for readability. A1200-second full cycle is a proposed timing experiment, not enabled gameplay pacing. The renderer's sun direction remains fixed; a complete moving sun/day-night art pass is still planned.

## Front lifecycle and player-centered arrival

Both story triggers and chance activations pass through the same handler. It draws a uniform random arrival angle from its own RNG stream exactly once per event.

| Phase | Default duration | Behavior |
|---|---:|---|
| Approach | 12s | Front develops at a random bearing and moves into the local region |
| Hold | 18s | Front center remains over the player while fields approach their targets |
| Clear | 12s | Influence fades toward the configured sunny/calm baseline; swell decays later |

Durations can be overridden per event payload. These deliberately short defaults are for inspection. Baseline sky/wind are configurable. Events temporarily perturb that baseline; persistent regional climates are not implemented yet.

`center = player_position + incoming_direction * approach_distance * (1 - smoothstep(progress))`

Approach distance is1.7 times the simulation radius (108.8m with defaults). Influence radius is0.9 times that radius (57.6m); smooth spatial falloff and lifecycle envelopes determine each cell's target conditions. At approach completion the center is exactly the player's current position, even while the player moves. This deliberately player-relative front guarantees arrival. It is not a freely advected weather system that the player can outrun. Positions remain continuous for continuous player travel.

Existing wind vectors do not turn when a distant event is merely scheduled: per-cell vector interpolation changes them only with the front's local influence. Cloud-bank presentation shows the incoming bearing and fades into local sky conditions. Wind and cloud visual responses use the shared fields; precise volumetric cloud transport is outside this study.

## Nested grids and connected physics

- Equal-sided cells:4m ×4m.
- Render radius8 cells:17×17 =289 nearby paper panels.
- Simulation radius16 cells:33×33 =1,089 field cells.
- Fixed simulation cadence30Hz, independent of rendering frame count.
- Packed per-cell fields: height, vertical velocity, amplitude, wind strength/vector components, cloud cover, rain and light. Sun time and continuous wave phase are shared scalars.
- Each cell has a spring response toward its wave target, damping and coupling to neighboring spring displacement. Coefficients: stiffness12, damping6, neighbor coupling1.2, unit effective mass. Semi-implicit integration runs at the fixed step.
- Bilinear height interpolation and its gradient supply the bucket and targeting normal. Connected sheets have separate positions/tilts; no colliding rigid body exists per drawing.

Grid cells have stable logical world IDs. Scrolling retains overlapping fields and initializes newly entering border cells. Only the nearby subset receives panel instances; a cheap backdrop covers the visible horizon beyond it. The current implementation copies bounded arrays on a cell crossing rather than using the final ring-buffer optimization. All simulated cells currently share one update cadence; cheaper outer-region updates remain a profiling task.

The visible grid follows the player, but full large-distance floating-origin rebasing of every gameplay actor is not implemented. The finite simulation also clamps queries outside its buffer, so interaction systems must respect local bounds; the current12m casting reach fits well inside it. Do not treat this as an infinite revisitable-world simulation.

## Rendering and known visual limits

The water study uses one original editable [SVG drawing](../../game/presentation/water_panel.svg), instanced on overlapping thin planes with individual physical positions/tilts. The shader supplies grain, horizon blending and bucket masking. A single near MultiMesh batch shares material/geometry; rain uses up to192 nearby instances. Future art needs multiple coherent water drawings and more deliberate view coverage.

Paper-sheet planes approximate the sampled surface with their centers and tilt; they are not a fully tessellated exact collision surface. Small decorative offsets and overlapped edges can differ from the bilinear gameplay sample. Significant visible mismatches require refinement before shipping. The current cards may expose repetitive patterns or obvious sheets at some angles; review motion before accepting this representation.

Lighting/rain/clouds are functional study effects. Clouds remain a procedural sky backdrop, rain droplets are a local visual volume, and the child/bucket remain rejected solid placeholders awaiting drawn replacements. No storm damage, lightning, gust model, soundscape, quest rewards or finished weather-specific wildlife behavior is claimed.

## Measured checks and limitations

On the M2 development Mac, an agent's120-step sample of the full grid plus289-panel export averaged **6.592ms per fixed tick**, excluding rendering. This is a CPU simulation/export measurement, not a60fps guarantee. Profile rendering, transparency, allocations and long movement before selecting production budgets. Shared phase/speed reduces seams but means propagation speed is not independently solved in every cell.

Test coverage includes all16 combinations, seeded approach and arrival over a moving player, speed-before-amplitude response, finite stable spring values, scrolling/negative IDs, height/normal agreement, no immediate local wind rotation, persistence replay and actual scene pause/targeting/rain/light integration. These checks establish a foundation, not final weather realism or approved asset cohesion.

Final integration run: all six headless suites passed (601 checks total); the graphical scene run passed16 checks including three saved frames. Calm and rain/strong captures were inspected at the travel view, confirming layered sheets, local rainfall and darker lighting. The current repeated drawing and solid subject remain visible art limitations. A later full-grid CPU sample measured6.615ms/tick; neither sample includes rendering.
