# Shared triggered and chance event system

Status: integrated coordinator and chance authoring implemented, 6 September 2026. Weather and the existing salvage fixture use one scheduler. Authored wildlife, puzzles, inventory rewards and story content remain future work.

## Ownership and activation

An event definition describes what can happen. Its activation policy describes why it starts. Its handler controls execution. Dispatch does not complete a quest, solve a puzzle or grant an achievement.

| Activation | Source | Intended use |
|---|---|---|
| `trigger` | Explicit request after prerequisites | Main-story progression, player actions and consequences |
| `chance` | Seeded eligible-time roll | Side opportunities and weather |
| `both` | Either path to the same handler | Reusable weather/encounter definitions |

Main-story prerequisites remain authored; chance supplies opportunities, not unearned achievements. Local steering and interactions retain consequences. Story-triggered and chance-triggered weather both arrive from a seeded random direction and center over the player.

The [coordinator](weather_encounter_scheduler.md) owns one pending request collection, weather/encounter track allocation, chance admission, cooldowns and quiet time. `environment_runtime.gd` routes commands and completions; weather owns front interpolation and physics, and encounter instances own local actors, modifiers and outcomes. Rendering never consumes chance RNG.

Weather capacity is **two total, including active**. Linked requests require both payloads and reserve both tracks atomically. An active encounter blocks new encounters and weather transitions through departure; a reserved encounter allows its required weather approach to run. Ordinary eligible requests can bypass blocked work safely, while viable story pairs drain tracks to prevent starvation.

## Definition and request contracts

See [eligibility/chance authoring](event_eligibility_and_chance.md) for the canonical schema, hard exclusions, wind × time weights, independent sky weights and tick conversion. `event_catalog.gd::scheduler_definitions()` supplies the enabled definitions. Configure before a run; configuration resets runtime state and is not a content-append API.

```gdscript
# Existing fixtures, not authored story content:
runtime.trigger_weather("sky", "cloudy")
runtime.trigger_encounter("salvage")
var result = runtime.submit_story(
    "test.sequence.1", "weather.mix.cloudy.breeze", "salvage", flags)
```

For explicit identity and optional tracks, use `scheduler.submit(request_id, weather_id, encounter_id, story, context)`. Its result is accepted/duplicate/full/invalid/ineligible. Submission validates both halves before mutation. Retain required story intent in its future owner when a queue is full; retry with the same ID and never treat queue admission as completion. A story pair requires both definitions. All requests recheck prerequisites before starting.

Definitions supply `eligibility.requires` and `eligibility.excludes` flags. Pass current flags to each `runtime.advance(delta, player_position, flags)` so withdrawn prerequisites do not become stale authorization. Hard environmental exclusions also apply to triggers; chance weights do not. Completed request IDs deduplicate retries, and per-definition `once` and cooldown rules control repetition.

## Pacing and execution

Physics/handler coordination runs at 30 Hz. The scheduler integrates eligible hazard and rolls at one-second intervals, separately for weather and encounters. Encounter aggregate hazard is capped at 1/240 eligible seconds with 90 seconds of guaranteed quiet after departure. Weather retains the existing sixteen-combination study rates with a separate 1/60 ceiling. Adding candidates cannot exceed those ceilings; below the ceiling, catalog size can still affect total frequency.

Explicit requests can wait; random opportunities do not accumulate behind locks. Ordinary fishing is not a protected scheduling gate, following the user's decision. Story requests currently respect post-encounter quiet time too.

Weather retains approach/hold/clear defaults and response constants in [runtime parameters](weather_runtime_parameters.md). During an encounter the macro phase is held, while waves, clouds, wind, rain and local modifier physics keep advancing. Side-event departure remains governed by [encounter fields and pacing](encounter_fields_and_pacing.md). Offscreen/out-of-range retirement and successful interaction remain different outcomes.

## Implementation and validation

- [environment_scheduler.gd](../../game/events/environment_scheduler.gd): pending requests, atomic reservations, eligibility, budgets, selection and persistence.
- [event_chance.gd](../../game/events/event_chance.gd): pure schema validation, interpolation and probability calculation.
- [event_catalog.gd](../../game/events/event_catalog.gd): enabled weather/salvage definitions; neutral time columns preserve existing balance.
- [environment_runtime.gd](../../game/events/environment_runtime.gd): synchronized stepping and handler routing.
- [weather_simulation.gd](../../game/world/weather_simulation.gd): front lifecycle, fields and base-weather authoring sample.
- [encounter_runtime.gd](../../game/events/encounter_runtime.gd): managed salvage handler, actors, visibility and departure.

See [scheduler implementation review](../work_packets/scheduler_chance_implementation.md) for tests and snapshot-version limits. The older `event_director.gd`, legacy catalog method and standalone salvage chance path remain tested study utilities; they are not parallel admission owners in the current game.

[Starter content ideas](starter_event_ideas.md) remain unselected. This scheduler work introduces no new wildlife, puzzle or story event.
