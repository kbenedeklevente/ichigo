# Encounter fields, weather-dependent chances and breathing room

Status: design proposal following the working weather study. The user requested weather-dependent event chances, no overlapping events, no weather transitions during an encounter, off-screen retirement, and wind-driven departure for lingering side events. The user approved90 seconds of quiet, at least240 seconds mean eligible random wait, and180-second side-event departure. They explicitly declined protecting ordinary hooked-fish fights from weather/events. A salvage-only runtime, global encounter/transition gate, sparse bounds index and local modifier composition are now implemented. Other event families and their draft rates remain future content work. See [implementation review](../work_packets/p2_wave_encounter_review.md).

## The data model

Separate an event's immutable definition, its live instance, its spatial index entry, and its optional influence on the world fields.

| Component | Responsibility |
|---|---|
| EventDefinition | ID, trigger/chance policy, prerequisites, weather eligibility/rates, priority, cooldown, side/story role, lifetime/departure policy, actor factory and possible outcomes |
| EventInstance | Instance ID, logical center, velocity, full bounds, lifecycle phase, timers, actors, interaction references, outcome and optional modifier sources |
| EventSpatialIndex | Sparse map from square cell IDs to event instance IDs, used to find events/actors near queried cells |
| LocalFieldModifier | Event-relative origin, cell size, extent, blend envelope, affected channels, values or analytic sampler |
| EnvironmentComposer | Samples the base weather and active modifiers, producing effective physics/rendering inputs |
| EncounterGate | Owns the one active encounter slot, weather-transition hold and quiet interval |

The event center is an anchor for placing its actors, not a replacement for its spatial extent. Index every cell intersecting its bounds or influence footprint, not only the cell containing the center. Use a sparse index rather than allocating a full matrix of event objects. It remains useful with one active encounter because multiple actors and a large influence footprint may belong to that encounter; completed/pending records need not have live renderers.

Event-local grids are optional. A simple gust can be an analytic falloff; a more involved local-current puzzle can use a small matrix. Translate local coordinates to stable logical world coordinates and resample into affected world cells. Local modifier cells can use the same base side length initially. Support differing resolutions only if needed, with explicit interpolation and unit conventions.

## Compose fields without corrupting the base simulation

Proposed engine order at each fixed physics step:

1. Read current eligibility/weather and the encounter gate. At scheduling ticks, evaluate queued triggers or chance admission only when allowed.
2. Advance active event timers, behavior, anchors and departure state. Refresh its spatial index footprint.
3. Advance base weather physics. If weather is held, keep its macro targets/front phase stable while existing waves, wind and cloud motion continue.
4. Sample only the active event's affected modifier cells and combine them with the base fields.
5. Integrate panel springs, bucket motion, actor drift and interaction physics from those effective inputs.
6. Render the near subset and report event visibility observations for the next simulation step.

`effective_wind = base_wind + sum(weight_i * event_wind_delta_i)`

For scalar channels, define units, allowed operations and limits per channel. Clamp cloud/rain fractions to[0,1], keep wave amplitudes nonnegative, and bound gust/current forces. Wave height is normally a result of the solver, so modify its forcing or target amplitude rather than repeatedly adding to the solved height. Reserve a separate temporary visual offset for genuinely decorative deformation.

Never add modifier arrays back into the persistent base each tick: that creates cumulative drift and makes removal impossible to reason about. Do not remove an event by subtracting its previous contribution from an already evolving field. Recompose from base plus current modifiers, with a fade-in/fade-out envelope. Residual physical motion then decays through the solver after a modifier ends.

This extends the existing simulation pipeline: its current `_step` combines weather targets and panel integration, so the implementation needs an explicit composition stage between them. Bucket, event actors, fishing targets and rendered panels must read the same effective surface; a renderer-only gust would fail the model.

## Exclusive encounters and stable weather

During an encounter, block all new encounter activations and all weather transitions, including automatic clearing of an established weather front. Keep ambient water/cloud/rain animation and ongoing physical response alive. A held weather state is not a paused world.

When the weather is already transitioning, delay encounter admission until conditions settle. When an encounter is active, retain triggered story/weather requests as pending and do not accumulate chance proposals. Do not interrupt an encounter just because a story trigger arrives. Finish departure and release the gate before dispatching the next eligible request.

The existing director's `exclusive_group='weather'` only serializes weather handlers. It does not yet satisfy this global encounter rule. Add an admission/transition gate at the integration level, rather than treating every internal weather stage as a separate competing event. A stable established weather front may supply the backdrop to an encounter, with its outgoing transition held until the encounter ends.

The local departure gust belongs to the current encounter's modifier field. It does not start another event or switch the base weather preset. This reconciles the requested stable weather with the requested wind-driven exit.

## Tick-independent chance rates

Keep the existing one-second scheduling tick unless profiling gives a reason to change it. Physics remains 30Hz; event placement/chance does not need to run at rendering frequency.

Author a rate per unit of eligible time, not an arbitrary percentage that changes meaning when the tick interval changes:

`p(dt) = 1 - exp(-lambda * dt)`

For a desired mean eligible wait of 240 seconds, the total event probability is 0.416% per 1s tick, 2.062% per 5s tick, or 4.081% per 10s tick. These describe the same distribution under stable conditions. A 0 rate stays exactly0 for every tick size.

Approved pacing controls (implemented for the salvage fixture):

- A 90-second guaranteed quiet interval after a side encounter leaves. Ordinary fishing remains available.
- A total random-event rate capped at one per 240 seconds of eligible idle time on average. This is not a deadline or a guarantee of an event every 4 minutes.
- Weather-dependent individual rates and per-family cooldowns; zero eligible rates mean no random encounter.
- Story triggers bypass the random roll but obey the active-encounter lock. Any policy for bypassing the post-encounter quiet interval must be explicit.
- Ordinary environmental animation is not a new encounter. Do not repeatedly interrupt fishing to present an event that is simply the usual rain or waves.

For eligible events with rates `lambda_i(weather)`, cap their total rate by scaling all rates proportionally when their sum exceeds the configured budget. Roll once with the resulting total rate, then select one event in proportion to its rate. This admits at most one event and avoids independent competing rolls producing accidental priority bias. Preserve trigger priority separately.

Read the current interpolated weather fields for eligibility; do not assume sky and wind are paired. Hard exclusions return0. Continuous rate interpolation can vary ordinary weights smoothly, with hysteresis for binary conditions. Test equal scenarios under different tick sizes; do not claim frame-independent behavior if inputs/eligibility change at different sampled times.

## First event candidates and draft chances

The table entries are **standalone probabilities over 60 seconds of eligible time**, before the shared rate cap, other event competition, wind adjustment, cooldowns and quiet intervals. Convert each percentage `P60` to `lambda = -ln(1 - P60) / 60`. These are gameplay proposals, not wildlife-frequency facts. Actual final occurrence probabilities are lower when the global rate cap applies.

| Candidate event | Sunny | Cloudy | Raincloud | Storm sky | Play / intended payoff |
|---|---:|---:|---:|---:|---|
| Passing fish shoal | 10% | 12% | 5% | 0% | Observe or fish during a brief schooling opportunity; L/V after ecological research |
| Drifting salvage | 5% | 7% | 9% | 4% | Position and intercept a recoverable object; C |
| Floating habitat | 5% | 7% | 3% | 0% | Observe local life and retrieve nearby material without disturbing it; L/C/V |
| Seabird gathering | 6% | 9% | 3% | 0% | Read a visible activity pattern, approach or disturb; L/V after research |
| Snagged line puzzle | 3% | 5% | 5% | 0% | Resolve visible tension/routing around drifting debris; C |
| Quiet animal passage | 3% | 3% | 1% | 0% | A species-appropriate visitor crosses nearby water; V, with interaction/avoidance |

Proposed wind multipliers below apply to the derived **rate**, not directly to the percentage:

| Candidate | Calm | Breeze | Strong | Storm wind |
|---|---:|---:|---:|---:|
| Fish shoal | 1.0 | 1.0 | 0.35 | 0 |
| Salvage | 0.6 | 1.0 | 1.3 | 0.5 |
| Floating habitat | 1.0 | 1.0 | 0.4 | 0 |
| Seabird gathering | 0.8 | 1.0 | 0.5 | 0 |
| Snagged line | 1.0 | 1.0 | 0.3 | 0 |
| Animal passage | 1.0 | 1.0 | 0.25 | 0 |

The weather preferences here prioritize visibility, interaction difficulty and pacing. Validate real species, ecosystem, behavior and educational content before treating them as natural-history facts. Do not invent a species simply to fill a rate table. All zeroes are design exclusions for this proposed slice, not claims that wildlife vanishes in bad weather.

Fishing inside a shoal encounter is one activity within that encounter, not a second scheduled event. Routine fishing outside encounters remains part of the main loop and does not require a special-event roll. Achievements are evaluated from real outcomes and do not occupy a second event slot.

## Lifetime, departure and off-screen retirement

Proposed lifecycle:

`arriving → present → departing → retired`

Keep outcome state separate: `unresolved`, `completed`, `failed`, or `abandoned`. An event can be completed while still visibly departing. An off-screen event can retire unresolved; that must not grant its reward. Use stable instance IDs and persist resolved outcomes to prevent re-entering a cell from rerolling the same encounter.

For side encounters, propose a 180-second maximum present time, followed by a 15–25-second departure gust ramp. The timer runs while nearby whether or not the player interacts, as requested. Interaction does not reset it indefinitely. Earlier natural drift out of view may retire the event sooner. The outgoing current/wind field should move its actors, not just their drawings.

A uniform wind applied equally to the bucket and event may never move the event relative to the camera. Use the modifier's local footprint and actors' physical drift response to create relative separation. Bound the departure force and choose an outward exit trajectory; do not teleport the event or alter player controls secretly. Verify that a player following it does not leave the encounter stuck forever. The exact force/drift policy and response of attached fishing lines need an implementation review.

Propose requiring the complete event bounds to be outside a padded viewport for 3 seconds and outside immediate interaction range before retirement. A center point alone can be off-screen while part of the encounter is still visible. Camera tilting or a moment of occlusion should not instantly clear the event. Decide what happens to an attached line as the event departs: it must visibly release, break under an agreed rule, or finish its supported interaction before cleanup; do not leave a dangling reference.

Story-required events may leave the rendered region but their unresolved milestone must remain pending, with a later opportunity to continue. The forced side-event timeout does not silently delete the only required story path. Keep the encounter lock through visible departure and release it after retirement; fade out modifiers and clean up all actor/interaction references through the owning systems.

## User answers and remaining review

1. **No:** ordinary hooked-fish fights do not hold off new encounters or weather transitions. Fishing within an already active world encounter inherits that encounter's lock; a fight is not a separate lock.
2. **Yes:**90 seconds guaranteed quiet, then a random wait averaging at least4 eligible minutes, with forced departure starting at3 minutes for a lingering side encounter even during interaction.

The first implementation enables only salvage, with its draft weather rate table and a total rate ceiling. Since one candidate is enabled, its actual mean random wait can be longer than4 minutes. The developer I key requests the fixture without waiting for a random roll, but still obeys the encounter lock and quiet period. O begins its departure as abandoned, not completed. This does not implement collection rewards or a fishing minigame.

The optional local-grid API exists; the salvage fixture uses an analytic gust. Full game saves and persistent custom-grid authoring remain future work. Future unanswered design questions still require explicit user input.

## Implementation sequence and checks

1. Approve initial event families, pacing and fishing protection; record outcomes separately from lifetime.
2. Extend the director with weather-derived rates and the shared admission gate. Test0% exclusions, total rate cap, timestep conversion, locks, queued triggers and quiet periods.
3. Add EventInstance and a sparse spatial index with full bounds and stable IDs; test moving, large and off-screen instances across cell boundaries.
4. Split base-field production, modifier composition and physics integration. Test local-grid coordinate transforms, bounded addition/subtraction, fade-out, exact base restoration and no cumulative drift.
5. Build one salvage event as the first integration fixture, including modifier-driven departure, before producing the full event library.
6. Verify weather phase holds while waves continue; then resumes coherently after retirement. Test active fishing lines, viewport changes, camera tilts, following a departing event, pause/save/resume and story continuity.
7. Playtest long quiet stretches and fishing focus. Measure encounter counts and waiting-time distributions across seeds; performance tests must confirm only affected cells are composed and distant events are not fully rendered.
